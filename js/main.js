const game = {
    player: new Player(),
    market: new Market(),
    travel: new TravelSystem(),

    init() {
        console.log("🚂 远行商人 - 游戏启动！");
        this.updateUI();
    },

    updateUI() {
        document.getElementById('day-display').textContent = `第 ${this.player.days} 天`;
        document.getElementById('gold-display').textContent = `💰 ${this.player.gold} 金币`;
        document.getElementById('location-display').textContent = `📍 ${this.player.currentCity}`;
    },

    buyGoods(goodName, quantity) {
        const prices = this.market.getCityPrices(this.player.currentCity);
        const price = prices[goodName];
        const cost = price * quantity;
        if (this.player.gold < cost) return { success: false, reason: "金币不足" };
        if (this.player.remainingCapacity < quantity) return { success: false, reason: "背包已满" };
        
        this.player.gold -= cost;
        this.player.addItem({ name: goodName, price }, quantity);
        this.updateUI();
        return { success: true, cost };
    },

    sellGoods(goodName, quantity) {
        const prices = this.market.getCityPrices(this.player.currentCity);
        const price = prices[goodName];
        const item = this.player.inventory.find(i => i.name === goodName);
        if (!item || item.quantity < quantity) return { success: false, reason: "库存不足" };
        
        this.player.gold += price * quantity;
        this.player.removeItem(goodName, quantity);
        this.updateUI();
        return { success: true, revenue: price * quantity };
    }
};

document.addEventListener('DOMContentLoaded', () => game.init());
