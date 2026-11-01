export interface Commodity {
  id: number;
  name: string;
  price: number;
  flowerLanguage: string;
  spec: string;
  emoji: string;
  color: string;
}

export const MOCK_COMMODITIES: Commodity[] = [
  { id: 1, name: '红玫瑰', price: 99, flowerLanguage: '热烈的爱', spec: '20支/束', emoji: '🌹', color: '#FCE4EC' },
  { id: 2, name: '粉玫瑰', price: 89, flowerLanguage: '初恋的悸动', spec: '11支/束', emoji: '🌸', color: '#F8BBD0' },
  { id: 3, name: '白百合', price: 129, flowerLanguage: '纯洁与祝福', spec: '5支/束', emoji: '🌼', color: '#FFF9C4' },
  { id: 4, name: '向日葵', price: 59, flowerLanguage: '沉默的爱', spec: '3支/束', emoji: '🌻', color: '#FFE0B2' },
  { id: 5, name: '郁金香', price: 79, flowerLanguage: '永恒的爱', spec: '10支/束', emoji: '🌷', color: '#E1BEE7' },
  { id: 6, name: '康乃馨', price: 49, flowerLanguage: '母爱与感恩', spec: '15支/束', emoji: '💐', color: '#F8BBD0' },
  { id: 7, name: '满天星', price: 39, flowerLanguage: '纯洁的思念', spec: '1束', emoji: '✨', color: '#CFD8DC' },
  { id: 8, name: '蓝色妖姬', price: 159, flowerLanguage: '珍贵与稀有', spec: '9支/束', emoji: '💠', color: '#B3E5FC' }
];
