export declare class Favorites {
    private favoritesList;
    private favorites;
    constructor();
    private init;
    private loadFavorites;
    private saveFavorites;
    addFavorite(name: string, progression: string[]): void;
    removeFavorite(id: number): void;
    private updateDisplay;
}
