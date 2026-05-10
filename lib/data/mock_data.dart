import '../models/auction_item.dart';
import '../models/bid.dart';

class MockData {
  static List<AuctionItem> getTrendingItems() {
    return [
      AuctionItem(
        id: '1',
        title: 'Vacheron Constantin Overseas Dual Time',
        description:
            'A masterpiece of haute horlogerie, this Vacheron Constantin Overseas Dual Time features an 18k rose gold case with a striking skeleton dial. The transparent sapphire case back reveals the intricate Calibre 2460 WT automatic movement. This rare timepiece combines technical sophistication with elegant design, making it a perfect addition to any serious watch collection.',
        imageUrl:
            'https://images.unsplash.com/photo-1622434641406-a158123450f9?w=800',
        currentBid: 42500,
        startingBid: 35000,
        endTime: DateTime.now().add(Duration(hours: 12, minutes: 34)),
        category: 'Watches',
        isFeatured: true,
        isVerified: true,
        totalBids: 24,
      ),
      AuctionItem(
        id: '2',
        title: 'Leica M3 Gold Edition',
        description:
            'An extremely rare Leica M3 Gold Edition from 1954, one of only 100 pieces ever made. Features 24k gold plating, original leather case, and comes with documentation of authenticity. This camera is not just a photographic tool but a piece of art history.',
        imageUrl:
            'https://images.unsplash.com/photo-1606933248010-ef1f33db8e44?w=800',
        currentBid: 12000,
        startingBid: 8000,
        endTime: DateTime.now().add(Duration(days: 2, hours: 5)),
        category: 'Photography',
        isFeatured: true,
        isVerified: true,
        totalBids: 18,
      ),
    ];
  }

  static List<AuctionItem> getLiveAuctions() {
    return [
      AuctionItem(
        id: '3',
        title: '2023 Stealth Phantom',
        description:
            'A state-of-the-art hypercar featuring a twin-turbo V12 engine producing 1,200 horsepower. Carbon fiber monocoque chassis, active aerodynamics, and bespoke interior crafted from the finest materials. Limited production of only 100 units worldwide.',
        imageUrl:
            'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=800',
        currentBid: 285000,
        startingBid: 250000,
        endTime: DateTime.now().add(
          Duration(hours: 4, minutes: 12, seconds: 44),
        ),
        category: 'Cars',
        isLive: true,
        isVerified: true,
        totalBids: 45,
        serialNumber: 'CHASSIS #001/100',
      ),
      AuctionItem(
        id: '4',
        title: 'Azure Skies Penthouse',
        description:
            'Breathtaking penthouse in Monte Carlo offering panoramic Mediterranean views. Features 5 bedrooms, 6 bathrooms, infinity pool, private gym, and wine cellar. Floor-to-ceiling windows throughout, with designer finishes and smart home technology.',
        imageUrl:
            'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800',
        currentBid: 1200000,
        startingBid: 1000000,
        endTime: DateTime.now().add(
          Duration(hours: 1, minutes: 54, seconds: 10),
        ),
        category: 'Real Estate',
        isLive: true,
        isVerified: true,
        totalBids: 32,
        location: 'MONTE CARLO, MONACO',
      ),
      AuctionItem(
        id: '5',
        title: 'Patek Philippe Nautilus 5711/1A',
        description:
            'The holy grail of sports watches. Discontinued stainless steel Nautilus with blue dial. Complete set with box and papers from 2021. This iconic Gerald Genta design has become one of the most sought-after watches in the world.',
        imageUrl:
            'https://images.unsplash.com/photo-1587836374828-4dbafa94cf0e?w=800',
        currentBid: 185000,
        startingBid: 150000,
        endTime: DateTime.now().add(Duration(hours: 6, minutes: 23)),
        category: 'Watches',
        isLive: true,
        isVerified: true,
        totalBids: 67,
      ),
    ];
  }

  static List<AuctionItem> getFeaturedItems() {
    return [
      AuctionItem(
        id: '6',
        title: 'Rolex Daytona 116500LN',
        description:
            'Iconic Rolex Cosmograph Daytona with ceramic bezel and white dial. Full set with box and papers from 2022.',
        imageUrl:
            'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=800',
        currentBid: 38000,
        startingBid: 30000,
        endTime: DateTime.now().add(Duration(days: 1, hours: 8)),
        category: 'Watches',
        isFeatured: true,
        isVerified: true,
        totalBids: 29,
      ),
      AuctionItem(
        id: '7',
        title: 'Hermès Birkin 35',
        description:
            'Rare Hermès Birkin 35 in Togo leather with gold hardware. Pristine condition with all original accessories.',
        imageUrl:
            'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800',
        currentBid: 22000,
        startingBid: 18000,
        endTime: DateTime.now().add(Duration(hours: 18)),
        category: 'Fashion',
        isFeatured: true,
        isVerified: true,
        totalBids: 15,
      ),
      AuctionItem(
        id: '8',
        title: 'Banksy Original Print',
        description:
            'Authenticated Banksy screen print from the 2008 series. Limited edition 12/500, comes with certificate of authenticity.',
        imageUrl:
            'https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8?w=800',
        currentBid: 45000,
        startingBid: 35000,
        endTime: DateTime.now().add(Duration(days: 3)),
        category: 'Art',
        isFeatured: true,
        isVerified: true,
        totalBids: 21,
      ),
      AuctionItem(
        id: '9',
        title: 'Audemars Piguet Royal Oak',
        description:
            'Classic Royal Oak in stainless steel with blue tapisserie dial. 41mm case, automatic movement.',
        imageUrl:
            'https://images.unsplash.com/photo-1614164185128-e4ec99c436d7?w=800',
        currentBid: 58000,
        startingBid: 50000,
        endTime: DateTime.now().add(Duration(days: 2)),
        category: 'Watches',
        isFeatured: true,
        isVerified: true,
        totalBids: 34,
      ),
      AuctionItem(
        id: '10',
        title: 'Ferrari 458 Italia',
        description:
            '2012 Ferrari 458 Italia in Rosso Corsa with beige leather interior. Only 12,000 miles, impeccable condition.',
        imageUrl:
            'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=800',
        currentBid: 195000,
        startingBid: 180000,
        endTime: DateTime.now().add(Duration(days: 4)),
        category: 'Cars',
        isFeatured: true,
        isVerified: true,
        totalBids: 28,
      ),
      AuctionItem(
        id: '11',
        title: 'Cartier Love Bracelet',
        description:
            'Classic Cartier Love bracelet in 18k yellow gold, size 17. Complete with original box and screwdriver.',
        imageUrl:
            'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800',
        currentBid: 7500,
        startingBid: 6000,
        endTime: DateTime.now().add(Duration(hours: 36)),
        category: 'Jewelry',
        isFeatured: true,
        isVerified: true,
        totalBids: 12,
      ),
    ];
  }

  static List<Bid> getBidHistory(String auctionItemId) {
    return [
      Bid(
        id: 'bid_1',
        auctionItemId: auctionItemId,
        userId: 'user_1',
        userName: 'Michael Chen',
        amount: 285000,
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        isWinning: true,
      ),
      Bid(
        id: 'bid_2',
        auctionItemId: auctionItemId,
        userId: 'user_2',
        userName: 'Sarah Williams',
        amount: 280000,
        timestamp: DateTime.now().subtract(Duration(minutes: 12)),
      ),
      Bid(
        id: 'bid_3',
        auctionItemId: auctionItemId,
        userId: 'user_3',
        userName: 'James Rodriguez',
        amount: 275000,
        timestamp: DateTime.now().subtract(Duration(hours: 1, minutes: 5)),
      ),
      Bid(
        id: 'bid_4',
        auctionItemId: auctionItemId,
        userId: 'user_4',
        userName: 'Emma Thompson',
        amount: 270000,
        timestamp: DateTime.now().subtract(Duration(hours: 2, minutes: 30)),
      ),
      Bid(
        id: 'bid_5',
        auctionItemId: auctionItemId,
        userId: 'user_5',
        userName: 'David Park',
        amount: 265000,
        timestamp: DateTime.now().subtract(Duration(hours: 3, minutes: 45)),
      ),
    ];
  }
}
