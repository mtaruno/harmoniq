"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Favorites = void 0;
class Favorites {
    constructor() {
        this.favorites = [];
        this.favoritesList = document.getElementById('favorites-list');
        this.favorites = this.loadFavorites();
        this.init();
    }
    init() {
        this.updateDisplay();
    }
    loadFavorites() {
        const savedFavorites = localStorage.getItem('harmoniq-favorites');
        return savedFavorites ? JSON.parse(savedFavorites) : [];
    }
    saveFavorites() {
        localStorage.setItem('harmoniq-favorites', JSON.stringify(this.favorites));
    }
    addFavorite(name, progression) {
        const favorite = {
            id: Date.now(),
            name: name,
            progression: progression,
            dateAdded: new Date().toISOString()
        };
        this.favorites.push(favorite);
        this.saveFavorites();
        this.updateDisplay();
    }
    removeFavorite(id) {
        this.favorites = this.favorites.filter(fav => fav.id !== id);
        this.saveFavorites();
        this.updateDisplay();
    }
    updateDisplay() {
        if (!this.favoritesList)
            return;
        this.favoritesList.innerHTML = '';
        this.favorites.forEach(favorite => {
            const favoriteElement = document.createElement('div');
            favoriteElement.className = 'favorite-item';
            favoriteElement.innerHTML = `
                <div class="favorite-header">
                    <h3>${favorite.name}</h3>
                    <button class="remove-favorite" data-id="${favorite.id}">×</button>
                </div>
                <div class="progression">
                    ${favorite.progression.join(' → ')}
                </div>
                <div class="date-added">
                    Added: ${new Date(favorite.dateAdded).toLocaleDateString()}
                </div>
            `;
            // Add remove button functionality
            const removeButton = favoriteElement.querySelector('.remove-favorite');
            if (removeButton) {
                removeButton.addEventListener('click', () => this.removeFavorite(favorite.id));
            }
            if (this.favoritesList) {
                this.favoritesList.appendChild(favoriteElement);
            }
        });
    }
}
exports.Favorites = Favorites;
// Initialize favorites when the page loads
document.addEventListener('DOMContentLoaded', () => {
    new Favorites();
});
//# sourceMappingURL=favorites.js.map