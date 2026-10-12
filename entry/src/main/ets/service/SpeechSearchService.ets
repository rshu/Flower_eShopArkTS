import { speechRecognizer } from '@kit.CoreSpeechKit';
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'SpeechSearch';

export interface VoiceRecognitionCallbacks {
  onStart: () => void;
  onResult: (text: string, isFinal: boolean) => void;
  onComplete: (finalText: string) => void;
  onError: (code: number, message: string) => void;
}

export class SpeechSearchService {
  private static engine: speechRecognizer.SpeechRecognitionEngine | undefined = undefined;
  private static capturer: audio.AudioCapturer | undefined = undefined;
  private static sessionId: string = '';
  private static running: boolean = false;
  private static lastText: string = '';
  private static maxTimer: number = -1;

  static async start(callbacks: VoiceRecognitionCallbacks): Promise<boolean> {
    if (SpeechSearchService.running) {
      return false;
    }
    try {
      const engine: speechRecognizer.SpeechRecognitionEngine =
        await speechRecognizer.createEngine(SpeechSearchService.buildEngineParams());
      SpeechSearchService.engine = engine;
      SpeechSearchService.sessionId = SpeechSearchService.newSessionId();
      SpeechSearchService.running = true;
      SpeechSearchService.lastText = '';

      let resolveStart: (ok: boolean) => void = () => {};
      const startPromise: Promise<boolean> = new Promise<boolean>((resolve) => {
        resolveStart = resolve;
      });

      engine.setListener({
        onStart: (sessionId: string, eventMessage: string): void => {
          console.info(TAG, `onStart ${sessionId} ${eventMessage}`);
          SpeechSearchService.running = true;
          callbacks.onStart();
          resolveStart(true);
        },
        onEvent: (sessionId: string, eventCode: number, eventMessage: string): void => {
          console.info(TAG, `onEvent ${sessionId} ${eventCode} ${eventMessage}`);
          // eventCode 3 = audio ends; stop feeding the engine so it can finalize.
          if (eventCode === 3) {
            SpeechSearchService.running = false;
          }
        },
        onResult: (sessionId: string, result: speechRecognizer.SpeechRecognitionResult): void => {
          console.info(TAG, `onResult ${sessionId} ${result.result} final=${result.isFinal}`);
          if (result.isFinal) {
            SpeechSearchService.lastText = result.result;
          }
          callbacks.onResult(result.result, result.isFinal);
        },
        onComplete: (sessionId: string, eventMessage: string): void => {
          console.info(TAG, `onComplete ${sessionId} ${eventMessage}`);
          SpeechSearchService.running = false;
          callbacks.onComplete(SpeechSearchService.lastText);
        },
        onError: (sessionId: string, errorCode: number, errorMessage: string): void => {
          console.error(TAG, `onError ${sessionId} ${errorCode} ${errorMessage}`);
          if (errorCode === 1002200010) {
            // Emitted by writeAudio when audio is fed before startListening has
            // taken effect. The start gate below prevents this; ignore if it
            // still races through.
            return;
          }
          SpeechSearchService.running = false;
          resolveStart(false);
          callbacks.onError(errorCode, errorMessage);
        }
      });

      // The engine needs a short settle time after createEngine before
      // startListening is accepted.
      await SpeechSearchService.sleep(500);

      try {
        engine.startListening(SpeechSearchService.buildStartParams(SpeechSearchService.sessionId));
        console.info(TAG, `startListening invoked for ${SpeechSearchService.sessionId}`);
      } catch (err) {
        SpeechSearchService.running = false;
        const e = err as BusinessError;
        console.error(TAG, `startListening threw: ${e.code} ${e.message}`);
        callbacks.onError(e.code, e.message);
        return false;
      }

      // startListening returns immediately; only feed audio after onStart
      // confirms the engine is listening. Give it up to 5s to start.
      const started: boolean = await Promise.race([
        startPromise,
        SpeechSearchService.sleep(5000).then(() => false)
      ]);
      if (!started) {
        SpeechSearchService.running = false;
        console.error(TAG, 'startListening did not confirm within timeout');
        return false;
      }

      // The engine can still reject the first audio writes if we feed it the
      // instant onStart fires; a short settle avoids a burst of 1002200010.
      await SpeechSearchService.sleep(300);

      // Safety stop in case VAD never fires; keeps us under the 20s engine limit.
      SpeechSearchService.maxTimer = setTimeout(() => {
        SpeechSearchService.running = false;
      }, 15000);

      await SpeechSearchService.startCapturerAndStream();
      SpeechSearchService.finishRecognition();
      return true;
    } catch (err) {
      SpeechSearchService.running = false;
      const e = err as BusinessError;
      console.error(TAG, `start failed: ${e.code} ${e.message}`);
      callbacks.onError(e.code, e.message);
      return false;
    }
  }

  private static finishRecognition(): void {
    if (SpeechSearchService.maxTimer !== -1) {
      clearTimeout(SpeechSearchService.maxTimer);
      SpeechSearchService.maxTimer = -1;
    }
    const engine: speechRecognizer.SpeechRecognitionEngine | undefined = SpeechSearchService.engine;
    if (engine !== undefined) {
      try {
        engine.finish(SpeechSearchService.sessionId);
      } catch (err) {
        const e = err as BusinessError;
        console.error(TAG, `finish failed: ${e.code} ${e.message}`);
      }
    }
    SpeechSearchService.releaseCapturer();
  }

  static stop(): void {
    SpeechSearchService.running = false;
    if (SpeechSearchService.maxTimer !== -1) {
      clearTimeout(SpeechSearchService.maxTimer);
      SpeechSearchService.maxTimer = -1;
    }
    const engine: speechRecognizer.SpeechRecognitionEngine | undefined = SpeechSearchService.engine;
    if (engine !== undefined) {
      try {
        engine.finish(SpeechSearchService.sessionId);
      } catch (err) {
        const e = err as BusinessError;
        console.error(TAG, `finish failed: ${e.code} ${e.message}`);
      }
    }
    SpeechSearchService.releaseCapturer();
  }

  static shutdown(): void {
    SpeechSearchService.stop();
    const engine: speechRecognizer.SpeechRecognitionEngine | undefined = SpeechSearchService.engine;
    if (engine !== undefined) {
      try {
        engine.shutdown();
      } catch (err) {
        const e = err as BusinessError;
        console.error(TAG, `shutdown failed: ${e.code} ${e.message}`);
      }
      SpeechSearchService.engine = undefined;
    }
  }

  static isRunning(): boolean {
    return SpeechSearchService.running;
  }

  private static releaseCapturer(): void {
    const capturer: audio.AudioCapturer | undefined = SpeechSearchService.capturer;
    if (capturer !== undefined) {
      capturer.stop().catch((err: BusinessError) => {
        console.error(TAG, `capturer stop failed: ${err.code} ${err.message}`);
      });
      capturer.release().catch((err: BusinessError) => {
        console.error(TAG, `capturer release failed: ${err.code} ${err.message}`);
      });
      SpeechSearchService.capturer = undefined;
    }
  }

  private static newSessionId(): string {
    return `sess_${Date.now()}`;
  }

  private static buildEngineParams(): speechRecognizer.CreateEngineParams {
    const extraParams: Record<string, Object> = {
      'locate': 'CN',
      'recognizerMode': 'short'
    };
    return {
      language: 'zh-CN',
      online: 1,
      extraParams: extraParams
    };
  }

  private static buildStartParams(sessionId: string): speechRecognizer.StartParams {
    const audioInfo: speechRecognizer.AudioInfo = {
      audioType: 'pcm',
      sampleRate: 16000,
      soundChannel: 1,
      sampleBit: 16
    };
    const extraParams: Record<string, Object> = {
      'recognitionMode': 0,
      'vadBegin': 2000,
      'vadEnd': 3000,
      'maxAudioDuration': 20000
    };
    return {
      sessionId: sessionId,
      audioInfo: audioInfo,
      extraParams: extraParams
    };
  }

  private static async startCapturerAndStream(): Promise<void> {
    const streamInfo: audio.AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
      channels: audio.AudioChannel.CHANNEL_1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
    };
    const capturerInfo: audio.AudioCapturerInfo = {
      source: audio.SourceType.SOURCE_TYPE_MIC,
      capturerFlags: 0
    };
    const options: audio.AudioCapturerOptions = {
      streamInfo: streamInfo,
      capturerInfo: capturerInfo
    };

    const capturer: audio.AudioCapturer = await audio.createAudioCapturer(options);
    SpeechSearchService.capturer = capturer;
    await capturer.start();

    const engine: speechRecognizer.SpeechRecognitionEngine | undefined = SpeechSearchService.engine;
    const sessionId: string = SpeechSearchService.sessionId;
    // 1280 bytes == 640 samples at 16-bit; the recognizer only accepts 640 or 1280 byte chunks.
    const CHUNK: number = 1280;
    while (SpeechSearchService.running && engine !== undefined) {
      const buffer: ArrayBuffer = await capturer.read(CHUNK, true);
      if (!SpeechSearchService.running) {
        break;
      }
      const pcm: Uint8Array = new Uint8Array(buffer);
      try {
        engine.writeAudio(sessionId, pcm);
      } catch (err) {
        const e = err as BusinessError;
        console.error(TAG, `writeAudio threw: ${e.code} ${e.message}`);
        if (e.code !== 1002200010) {
          break;
        }
      }
    }
  }

  private static sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => resolve(), ms);
    });
  }
}
