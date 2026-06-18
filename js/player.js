class Player {
    constructor(name = "行商") {
        this.name = name;
        this.gold = 100;
        this.inventory = [];
        this.maxCapacity = 20;
        this.currentCity = "起始之城";
        this.days = 1;
        this.reputation = 0;
    }

    get usedCapacity() {
        return this.inventory.reduce((sum, item) => sum + item.quantity, 0);
    }

    get remainingCapacity() {
        return this.maxCapacity - this.usedCapacity;
    }

    addItem(item, quantity) {
        if (this.remainingCapacity < quantity) return false;
        const existing = this.inventory.find(i => i.name === item.name);
        if (existing) {
            existing.quantity += quantity;
        } else {
            this.inventory.push({ ...item, quantity });
        }
        return true;
    }

    removeItem(itemName, quantity) {
        const idx = this.inventory.findIndex(i => i.name === itemName);
        if (idx === -1) return false;
        if (this.inventory[idx].quantity < quantity) return false;
        this.inventory[idx].quantity -= quantity;
        if (this.inventory[idx].quantity === 0) {
            this.inventory.splice(idx, 1);
        }
        return true;
    }

    nextDay() {
        this.days++;
    }
}

if (typeof module !== 'undefined') module.exports = Player;
