class TravelSystem {
    constructor() {
        this.cities = [
            { name: "起始之城", region: "平原" },
            { name: "铁炉堡", region: "山地" },
            { name: "丝绸港", region: "沿海" },
            { name: "香料群岛", region: "热带" },
            { name: "宝石谷", region: "沙漠" }
        ];
        this.distanceMap = {};
        this._initDistances();
    }

    _initDistances() {
        for (let i = 0; i < this.cities.length; i++) {
            for (let j = i + 1; j < this.cities.length; j++) {
                const dist = Math.floor(Math.random() * 5) + 1;
                this.distanceMap[`${i}-${j}`] = dist;
                this.distanceMap[`${j}-${i}`] = dist;
            }
        }
    }

    getDistance(cityA, cityB) {
        const iA = this.cities.findIndex(c => c.name === cityA);
        const iB = this.cities.findIndex(c => c.name === cityB);
        if (iA === -1 || iB === -1) return 999;
        return this.distanceMap[`${iA}-${iB}`] || 0;
    }

    travel(player, targetCity) {
        const dist = this.getDistance(player.currentCity, targetCity);
        for (let i = 0; i < dist; i++) {
            player.nextDay();
        }
        player.currentCity = targetCity;
        return dist;
    }
}

if (typeof module !== 'undefined') module.exports = TravelSystem;
