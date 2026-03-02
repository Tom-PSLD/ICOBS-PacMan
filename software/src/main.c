#include "system.h"
#include <stdlib.h> 
#include <math.h>

// ============================================================================
// 1. CONFIGURATION
// ============================================================================

#define VGA_PTR ((VGA_t *) VGA_BASE) 
#define SEG7_DISPLAY  (MY_PERIPH.REG1) 

#define TILE_SIZE 32
#define MAP_ROWS  15
#define MAP_COLS  20
#define SCREEN_W  640
#define SCREEN_H  480

#define ORIG_W 85
#define ORIG_H 85
#define DISPLAY_W (ORIG_W * 2) 
#define DISPLAY_H (ORIG_H * 2) 
#define CENTER_X ((SCREEN_W - DISPLAY_W) / 2) 
#define WIN_Y_POS 100 

#define PACMAN_SPEED 4
#define GHOST_SPEED  2 // Doit être un diviseur de 32 (1, 2, 4, 8) pour que l'alignement fonctionne

// ============================================================================
// 2. DONNÉES DE LA CARTE (Votre version)
// ============================================================================

const int map_grid[MAP_ROWS][MAP_COLS] = {
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}, 
    {1,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,1}, 
    {1,0,1,1,1,0,1,0,1,1,1,1,1,0,1,0,1,1,1,1}, 
    {1,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1}, 
    {1,0,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,0,1,1}, 
    {1,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,1}, 
    {1,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1}, 
    {0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0}, 
    {1,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1}, 
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1}, 
    {1,0,1,1,1,0,1,1,1,0,1,1,1,0,1,1,1,0,1,1}, 
    {1,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1}, 
    {1,1,1,0,1,0,1,0,1,1,1,0,1,0,1,0,1,1,1,1}, 
    {1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,1}, 
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}  
};

const int dots_init[MAP_ROWS][MAP_COLS] = {
    {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 
    {0,1,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,0}, 
    {0,1,0,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,0}, 
    {0,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,0}, 
    {0,1,0,1,0,0,0,1,0,1,0,1,0,0,0,1,0,1,0,0}, 
    {0,1,1,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1,1,0}, 
    {0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0}, 
    {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 
    {0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0}, 
    {0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0}, 
    {0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0}, 
    {0,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0}, 
    {0,0,0,1,0,1,0,1,0,0,0,1,0,1,0,1,0,0,0,0}, 
    {0,1,1,1,1,1,0,1,1,1,1,1,0,1,1,1,1,1,1,0}, 
    {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}  
};
int dots_status[MAP_ROWS][MAP_COLS];
int total_dots = 0;
int score = 0;

typedef struct { int x, y, dx, dy; } Entity;
Entity pacman, ghost2, ghost3, ghost6; 

// ============================================================================
// 3. FONCTIONS UTILITAIRES
// ============================================================================

void delay_loop(int count) {
    for (volatile int i = 0; i < count; i++);
}

// Fonction utilitaire pour vérifier si une case de la grille est libre
int is_walkable(int col, int row) {
    if (col < 0 || col >= MAP_COLS || row < 0 || row >= MAP_ROWS) return 0;
    return (map_grid[row][col] == 0);
}

int check_collision(int x, int y) {
    // Marge réduite pour que le fantôme reste bien dans les couloirs
    int margin = 2; // Petite marge pour la précision
    int size = 32 - (2 * margin); 
    
    int corners_x[4] = {x + margin, x + margin + size, x + margin, x + margin + size};
    int corners_y[4] = {y + margin, y + margin, y + margin + size, y + margin + size};
    
    for(int i=0; i<4; i++) {
        int c = corners_x[i] / TILE_SIZE;
        int r = corners_y[i] / TILE_SIZE;
        if (c < 0 || c >= MAP_COLS || r < 0 || r >= MAP_ROWS) return 1;
        if (map_grid[r][c] == 1) return 1;
    }
    return 0; 
}

void update_score_display() {
    unsigned int u = score % 10;
    unsigned int d = (score / 10) % 10;
    unsigned int c = (score / 100) % 10;
    unsigned int m = (score / 1000) % 10;
    SEG7_DISPLAY = (m << 12) | (c << 8) | (d << 4) | u;
}

// ============================================================================
// 4. LOGIQUE DE JEU
// ============================================================================

void init_game_logic() {
    score = 0;
    total_dots = 0;
    for(int r=0; r<MAP_ROWS; r++) {
        for(int c=0; c<MAP_COLS; c++) {
            if (dots_init[r][c] == 1) {
                dots_status[r][c] = 1;
                total_dots++;
            } else {
                dots_status[r][c] = 0;
            }
        }
    }
    update_score_display();

    // Reset visuel gommes
    VGA_PTR->background_color = 0x80000000; 
    for(volatile int i=0; i<1000; i++); 
    VGA_PTR->background_color = 0x00000000; 
}

void random_spawn(Entity *e) {
    int r, c;
    int is_valid = 0;
    while (!is_valid) {
        r = rand() % MAP_ROWS;
        c = rand() % MAP_COLS;
        int in_ghost_house = (r >= 6 && r <= 8) && (c >= 8 && c <= 12);
        if (map_grid[r][c] == 0 && r != 7 && !in_ghost_house) {
            is_valid = 1;
        }
    }
    // +1 pour l'alignement (Important pour la logique de grille)
    e->x = c * TILE_SIZE + 1; 
    e->y = r * TILE_SIZE + 1;
}

void reset_round() {
    pacman.x = 1 * TILE_SIZE; 
    pacman.y = 7 * TILE_SIZE;
    pacman.dx = 0; pacman.dy = 0;

    random_spawn(&ghost2); ghost2.dx = GHOST_SPEED; ghost2.dy = 0;
    random_spawn(&ghost3); ghost3.dx = 0; ghost3.dy = GHOST_SPEED;
    random_spawn(&ghost6); ghost6.dx = -GHOST_SPEED; ghost6.dy = 0;
    
    VGA_PTR->X1_pos = pacman.x; VGA_PTR->Y1_pos = pacman.y;
    VGA_PTR->X2_pos = ghost2.x; VGA_PTR->Y2_pos = ghost2.y;
    VGA_PTR->X3_pos = ghost3.x; VGA_PTR->Y3_pos = ghost3.y;
    VGA_PTR->X6_pos = ghost6.x; VGA_PTR->Y6_pos = ghost6.y;
    
    VGA_PTR->X4_pos = 700; VGA_PTR->Y4_pos = 0; 
    VGA_PTR->X5_pos = 220; VGA_PTR->Y5_pos = 199; 
}

// ============================================================================
// 5. MAIN LOOP
// ============================================================================
int main() {
    RSTCLK.CLKENR |= 0xFFFFFFFF; 
    
    init_game_logic(); 
    reset_round();     

    while(1) {
        // A. VICTOIRE
        if (score >= total_dots && total_dots > 0) {
            VGA_PTR->X4_pos = CENTER_X; VGA_PTR->Y4_pos = WIN_Y_POS; 
            while(1) { } 
        }

        // B. PACMAN MOVEMENT (Hitbox permissive pour virages faciles)
        int nx = pacman.x; int ny = pacman.y;
        if (GPIOC.IDRbits.P0) ny -= PACMAN_SPEED;      
        else if (GPIOC.IDRbits.P3) ny += PACMAN_SPEED; 
        if (GPIOC.IDRbits.P1) nx -= PACMAN_SPEED; 
        else if (GPIOC.IDRbits.P2) nx += PACMAN_SPEED; 

        if (nx < 0) nx = (pacman.y/32 == 7) ? SCREEN_W - 32 : 0;
        else if (nx > SCREEN_W - 32) nx = (pacman.y/32 == 7) ? 0 : SCREEN_W - 32;

        // Pour Pacman, on utilise le check_collision pixel par pixel
        if (!check_collision(nx, pacman.y)) pacman.x = nx;
        if (!check_collision(pacman.x, ny)) pacman.y = ny;

        // C. MANGER
        int gx = (pacman.x + 16) / 32; int gy = (pacman.y + 16) / 32;
        if (gx >= 0 && gx < MAP_COLS && gy >= 0 && gy < MAP_ROWS) {
            if (dots_status[gy][gx] == 1) {
                dots_status[gy][gx] = 0; score++; update_score_display();   
            }
        }

        // --- D. INTELLIGENCE ARTIFICIELLE DES FANTÔMES (Basée sur la MAP) ---
        // Le principe : Si le fantôme est aligné sur la grille, il décide d'une direction.
        // Il ne fait pas demi-tour sauf impasse.
        
        Entity *enemies[] = {&ghost2, &ghost3, &ghost6};
        
        // Directions : 0:Haut, 1:Bas, 2:Gauche, 3:Droite
        int dirs_dx[4] = {0, 0, -GHOST_SPEED, GHOST_SPEED};
        int dirs_dy[4] = {-GHOST_SPEED, GHOST_SPEED, 0, 0};
        
        for(int i=0; i<3; i++) {
            Entity *e = enemies[i];

            // 1. Est-on au centre d'une tuile (intersection potentielle) ?
            // Les positions sont à +1 pixel (ex: 1, 33, 65...), donc (pos-1) % 32 == 0
            if ( ((e->x - 1) % TILE_SIZE == 0) && ((e->y - 1) % TILE_SIZE == 0) ) {
                
                int grid_x = (e->x - 1) / TILE_SIZE;
                int grid_y = (e->y - 1) / TILE_SIZE;
                
                // Déterminer la direction actuelle pour éviter le demi-tour immédiat
                int current_dir = -1;
                if (e->dy < 0) current_dir = 0; // Haut
                else if (e->dy > 0) current_dir = 1; // Bas
                else if (e->dx < 0) current_dir = 2; // Gauche
                else if (e->dx > 0) current_dir = 3; // Droite
                
                int opposite_dir = -1;
                if(current_dir == 0) opposite_dir = 1;
                if(current_dir == 1) opposite_dir = 0;
                if(current_dir == 2) opposite_dir = 3;
                if(current_dir == 3) opposite_dir = 2;

                // Lister les directions possibles (sans mur)
                int valid_dirs[4];
                int count = 0;
                
                // Test Haut
                if (is_walkable(grid_x, grid_y - 1)) valid_dirs[count++] = 0;
                // Test Bas
                if (is_walkable(grid_x, grid_y + 1)) valid_dirs[count++] = 1;
                // Test Gauche
                if (is_walkable(grid_x - 1, grid_y)) valid_dirs[count++] = 2;
                // Test Droite
                if (is_walkable(grid_x + 1, grid_y)) valid_dirs[count++] = 3;
                
                // 2. Choisir une nouvelle direction
                if (count > 0) {
                    // Si on a le choix (>1), on essaie de filtrer le demi-tour
                    // Sauf si c'est la seule option (cul de sac)
                    if (count > 1 && opposite_dir != -1) {
                        int filtered_dirs[4];
                        int f_count = 0;
                        for(int k=0; k<count; k++) {
                            if(valid_dirs[k] != opposite_dir) {
                                filtered_dirs[f_count++] = valid_dirs[k];
                            }
                        }
                        // Choisir au hasard parmi les directions filtrées
                        if (f_count > 0) {
                            int pick = rand() % f_count;
                            int new_dir = filtered_dirs[pick];
                            e->dx = dirs_dx[new_dir];
                            e->dy = dirs_dy[new_dir];
                        }
                    } else {
                        // Soit cul de sac, soit démarrage : on prend au hasard parmi les valides
                        int pick = rand() % count;
                        int new_dir = valid_dirs[pick];
                        e->dx = dirs_dx[new_dir];
                        e->dy = dirs_dy[new_dir];
                    }
                }
            }
            
            // 3. Appliquer le mouvement
            // Même avec la logique ci-dessus, on garde une sécurité anti-mur
            int next_x = e->x + e->dx;
            int next_y = e->y + e->dy;
            
            // Si jamais la logique de grille a raté (ex: collision imprévue), on stop
            if (check_collision(next_x, next_y)) {
                // Bloqué (ne devrait pas arriver souvent avec la logique ci-dessus)
                // On fait juste demi-tour pour se débloquer au prochain cycle
                e->dx = -e->dx; 
                e->dy = -e->dy; 
            } else {
                e->x = next_x;
                e->y = next_y;
            }
        }

        // E. GAME OVER
        int d2 = abs(pacman.x - ghost2.x) + abs(pacman.y - ghost2.y);
        int d3 = abs(pacman.x - ghost3.x) + abs(pacman.y - ghost3.y);
        int d6 = abs(pacman.x - ghost6.x) + abs(pacman.y - ghost6.y);
        
        if (d2 < 20 || d3 < 20 || d6 < 20) { 
            VGA_PTR->background_color = 0x00F00000; 
            delay_loop(2000000); 
            init_game_logic(); 
            reset_round();     
        }

        // F. UPDATE VGA
        VGA_PTR->X1_pos = pacman.x; VGA_PTR->Y1_pos = pacman.y;
        VGA_PTR->X2_pos = ghost2.x; VGA_PTR->Y2_pos = ghost2.y;
        VGA_PTR->X3_pos = ghost3.x; VGA_PTR->Y3_pos = ghost3.y;
        VGA_PTR->X6_pos = ghost6.x; VGA_PTR->Y6_pos = ghost6.y;
        
        delay_loop(50000); 
    }
}