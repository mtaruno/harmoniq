interface Favorite {
    id: number;
    name: string;
    progression: string[];
    dateAdded: string;
}

export class Favorites {
    private favoritesList: HTMLElement | null;
    private favorites: Favorite[] = [];

    constructor() {
        this.favoritesList = document.getElementById('favorites-list');
        this.favorites = this.loadFavorites();
        this.init();
    }

    private init(): void {
        this.updateDisplay();
    }

    private loadFavorites(): Favorite[] {
        const savedFavorites = localStorage.getItem('harmoniq-favorites');
        return savedFavorites ? JSON.parse(savedFavorites) : [];
    }

    private saveFavorites(): void {
        localStorage.setItem('harmoniq-favorites', JSON.stringify(this.favorites));
    }

    public addFavorite(name: string, progression: string[]): void {
        const favorite: Favorite = {
            id: Date.now(),
            name: name,
            progression: progression,
            dateAdded: new Date().toISOString()
        };

        this.favorites.push(favorite);
        this.saveFavorites();
        this.updateDisplay();
    }

    public removeFavorite(id: number): void {
        this.favorites = this.favorites.filter(fav => fav.id !== id);
        this.saveFavorites();
        this.updateDisplay();
    }

    private updateDisplay(): void {
        if (!this.favoritesList) return;

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

// Initialize favorites when the page loads
document.addEventListener('DOMContentLoaded', () => {
    new Favorites();
}); 