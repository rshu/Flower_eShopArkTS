import { Commodity, Store } from '../model/Commodity';

export class MockData {
  static readonly COMMODITIES: Commodity[] = [
    {
      id: 1,
      name: 'Red Rose Bouquet',
      price: 99.0,
      image: 'https://picsum.photos/seed/rose/600/400',
      description: 'Fresh red roses, hand-tied with seasonal greenery.',
      flowerLanguage: 'Passionate love and romance',
      spec: '11 stems / 60cm',
      stock: 20
    },
    {
      id: 2,
      name: 'Pink Lily Arrangement',
      price: 128.0,
      image: 'https://picsum.photos/seed/lily/600/400',
      description: 'Elegant pink lilies in a glass vase.',
      flowerLanguage: 'Purity and prosperity',
      spec: '6 stems / vase included',
      stock: 12
    },
    {
      id: 3,
      name: 'Sunflower Basket',
      price: 79.0,
      image: 'https://picsum.photos/seed/sunflower/600/400',
      description: 'Bright sunflowers that bring sunshine home.',
      flowerLanguage: 'Admiration and loyalty',
      spec: '5 stems / basket',
      stock: 30
    },
    {
      id: 4,
      name: 'White Carnation Set',
      price: 66.0,
      image: 'https://picsum.photos/seed/carnation/600/400',
      description: 'Classic white carnations for every occasion.',
      flowerLanguage: 'Pure love and good luck',
      spec: '10 stems / wrapped',
      stock: 25
    },
    {
      id: 5,
      name: 'Blue Hydrangea Pot',
      price: 158.0,
      image: 'https://picsum.photos/seed/hydrangea/600/400',
      description: 'Lush blue hydrangea in a ceramic pot.',
      flowerLanguage: 'Gratitude and heartfelt emotion',
      spec: '1 pot / 40cm',
      stock: 8
    },
    {
      id: 6,
      name: 'Tulip Mix',
      price: 88.0,
      image: 'https://picsum.photos/seed/tulip/600/400',
      description: 'Colorful tulip mix, freshly cut.',
      flowerLanguage: 'Perfect love and new beginnings',
      spec: '12 stems / mixed colors',
      stock: 18
    },
    {
      id: 7,
      name: 'Orchid Single',
      price: 199.0,
      image: 'https://picsum.photos/seed/orchid/600/400',
      description: 'Exquisite single-stem orchid in minimal vase.',
      flowerLanguage: 'Luxury, beauty and strength',
      spec: '1 stem / vase',
      stock: 6
    },
    {
      id: 8,
      name: 'Daisy Fresh Box',
      price: 59.0,
      image: 'https://picsum.photos/seed/daisy/600/400',
      description: 'Cheerful daisies in a gift box.',
      flowerLanguage: 'Innocence and cheerfulness',
      spec: 'box of 20 stems',
      stock: 40
    },
    {
      id: 9,
      name: 'Peony Bloom',
      price: 138.0,
      image: 'https://picsum.photos/seed/peony/600/400',
      description: 'Romantic peony blooms, seasonal limited.',
      flowerLanguage: 'Prosperity and honor',
      spec: '5 stems / wrapped',
      stock: 10
    },
    {
      id: 10,
      name: 'Mixed Rose Box',
      price: 168.0,
      image: 'https://picsum.photos/seed/mixedrose/600/400',
      description: 'Premium mixed rose gift box with care card.',
      flowerLanguage: 'Love in every color',
      spec: '18 stems / gift box',
      stock: 15
    }
  ];

  static readonly STORES: Store[] = [
    {
      id: 1,
      name: 'Flower eShop Flagship',
      address: 'No.1 Huayuan Road, Downtown',
      phone: '021-88886666',
      latitude: 31.2304,
      longitude: 121.4737
    },
    {
      id: 2,
      name: 'Flower eShop Riverside',
      address: 'No.88 Binjiang Avenue',
      phone: '021-77775555',
      latitude: 31.2397,
      longitude: 121.4998
    },
    {
      id: 3,
      name: 'Flower eShop Tech Park',
      address: 'No.66 Innovation Street',
      phone: '021-66664444',
      latitude: 31.1946,
      longitude: 121.5890
    },
    {
      id: 4,
      name: 'Flower eShop Garden Mall',
      address: 'No.500 Garden Plaza',
      phone: '021-55553333',
      latitude: 31.2100,
      longitude: 121.4360
    },
    {
      id: 5,
      name: 'Flower eShop Airport',
      address: 'Terminal 2, International Airport',
      phone: '021-44442222',
      latitude: 31.1443,
      longitude: 121.8083
    }
  ];

  static getCommodityById(id: number): Commodity | undefined {
    return MockData.COMMODITIES.find((item: Commodity): boolean => item.id === id);
  }

  static getStoreById(id: number): Store | undefined {
    return MockData.STORES.find((item: Store): boolean => item.id === id);
  }
}
