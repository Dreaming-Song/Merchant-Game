class Market {
    constructor() {
        this.goods = {
            "小麦": { basePrice: 10, volatility: 0.3 },
            "铁矿": { basePrice: 25, volatility: 0.4 },
            "丝绸": { basePrice: 50, volatility: 0.5 },
            "香料": { basePrice: 40, volatility: 0.6 },
            "宝石": { basePrice: 100, volatility: 0.7 },
            "木材": { basePrice: 8, volatility: 0.2 },
            "陶器": { basePrice: 15, volatility: 0.3 },
            "酒": { basePrice: 30, volatility: 0.5 }
        };
    }

    getCityPrices(cityName) {
        const prices = {};
        for (const [name, data] of Object.entries(this.goods)) {
            const variation = 1 + (Math.random() - 0.5) * 2 * data.volatility;
            prices[name] = Math.round(data.basePrice * variation);
        }
        return prices;
    }

    calculateProfit(buyPrice, sellPrice, quantity) {
        return (sellPrice - buyPrice) * quantity;
    }
}

if (typeof module !== 'undefined') module.exports = Market;
