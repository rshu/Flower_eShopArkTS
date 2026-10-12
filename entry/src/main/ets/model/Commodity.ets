export interface Commodity {
  id: number;
  name: string;
  price: number;
  image: string;
  description: string;
  flowerLanguage: string;
  spec: string;
  stock: number;
}

export interface Store {
  id: number;
  name: string;
  address: string;
  phone: string;
  latitude: number;
  longitude: number;
}

export interface DeliveryAddress {
  name: string;
  phone: string;
  address: string;
}

export interface PhotoReviewItem {
  uri: string;
}
