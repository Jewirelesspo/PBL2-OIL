import javax.swing.JOptionPane;
import java.util.ArrayList;
import java.util.Arrays;

int inputValue = -1; // 初期値を設定 (未使用だが残しておく)

int cols, rows;  // グリッドの列数と行数
int cellSize = 10;  // セルのサイズ
float D = 0.07;  // 拡散係数（0～1）を調整 (移動確率に影響)
int[][] grid, nextGrid;  // 現在のグリッドと次の状態を保持するグリッド
float[][] potential; // ポテンシャルエネルギーマップ

int navHeight = 80; // ナビゲーションバーの高さ
int playerOil = 10000;
int enemyOil = 100;

// 拠点の座標と所有者（0: なし, 1: プレイヤー, 2: 敵）
ArrayList<PVector> bases = new ArrayList<>();
int[] baseOwners;
int[] baseOil; // 各拠点の持つ原油数
int numBases = 4; // 拠点の数

// 油田の座標
ArrayList<PVector> oilFields = new ArrayList<>();
int numOilFields = 10;

boolean gameStarted = false; // シミュレーションが開始されたかどうかのフラグ

void setup() {
    size(1080, 720);
    cols = width / cellSize;
    rows = (height - navHeight) / cellSize; // 明示的に切り捨て
    println("cols: " + cols + ", rows: " + rows);

    grid = new int[cols][rows];
    nextGrid = new int[cols][rows];
    potential = new float[cols][rows];

    generateRandomBases();
    baseOwners = new int[bases.size()]; // 初期状態は所有者なし
    baseOil = new int[bases.size()];   // 初期状態は原油0

    // 油田のランダム配置
    for (int i = 0; i < numOilFields; ++i) {
        oilFields.add(createValidOilFieldPosition());
    }

    println(bases.size());
    // グリッドの初期化（拠点を設定）
    for (int i = 0; i < bases.size(); ++i) {
        grid[(int) bases.get(i).x][(int) bases.get(i).y] = 3 + i;
    }

    initializePotential(); // ポテンシャルマップの初期化
}

void initializePotential() {
    for (int i = 0; i < cols; i++) {
        for (int j = 0; j < rows; j++) {
            for(int k = 0; k < bases.size(); k++){
                float baseDist = dist(i, j, bases.get(k).x, bases.get(k).y);
                //if (baseDist < 4) potential[i][j] -= 0.005 / baseDist;
                potential[i][j] -= (float)i / (float)width;
            }
        }
    }
}

void generateRandomBases() {
    bases.clear();
    for (int i = 0; i < numBases; ++i) {
        PVector newBase;
        boolean validPosition = false;
        while (!validPosition) {
            newBase = new PVector(floor(random(cols)), floor(random(rows)));
            boolean tooClose = false;
            for (PVector existingBase : bases) {
                if (dist(newBase.x, newBase.y, existingBase.x, existingBase.y) < 10) {
                    tooClose = true;
                    break;
                }
            }
            if (!tooClose) {
                bases.add(newBase);
                validPosition = true;
            }
        }
    }
}

PVector createValidOilFieldPosition() {
    PVector pos = new PVector();
    boolean valid = false;
    while (!valid) {
        pos = new PVector(floor(random(cols)), floor(random(rows)));
        boolean overlaps = false;
        for (PVector base : bases) {
            if (dist(pos.x, pos.y, base.x, base.y) < 5) {
                overlaps = true;
                break;
            }
        }
        if (!overlaps) {
            valid = true;
        }
    }
    return pos;
}

void draw() {
    background(240);
    drawGrid();  // グリッドを描画
    drawUI();    // UIを描画

    if (gameStarted) {
        updateCell();  // グリッドを更新
        checkWinCondition(); // 勝利条件のチェック
        // 敵のターンを一定間隔で実行
        if (frameCount % 60 == 30) { // 少しずらして実行
            //enemyTurn();
        }
    } else {
        fill(0);
        textSize(20);
        textAlign(CENTER, CENTER);
        text("Click on your bases to allocate initial oil.", width / 2, navHeight + 30);
        text("Click 'Start Simulation' to begin.", width / 2, navHeight + 60);
    }
}

void drawGrid() {
    for (int i = 0; i < cols; ++i) {
        for (int j = 0; j < rows; ++j) {
            if (grid[i][j] == 1) {
                fill(10, 10, 10); // プレイヤー油: 黒
            } else if (grid[i][j] == 2) {
                fill(200, 0, 0); // 敵の油: 赤
            } else if (grid[i][j] >= 3 && grid[i][j] <= 6) {
                int baseIndex = grid[i][j] - 3;
                if (baseOwners[baseIndex] == 1) {
                    fill(0, 150, 0); // プレイヤーの都市
                } else if (baseOwners[baseIndex] == 2) {
                    fill(150, 150, 0); // 敵の都市
                } else {
                    fill(150);      // 中立の拠点
                }
            } else {
                fill(255);  // 空セルは白
            }
            strokeWeight(0.2);
            stroke(200);
            rect(i * cellSize, j * cellSize + navHeight, cellSize, cellSize); // y座標を調整
        }
    }

    // 油田を描画
    fill(255, 200, 0); // 黄色
    for (PVector oilField : oilFields) {
        ellipse(oilField.x * cellSize + cellSize / 2, oilField.y * cellSize + navHeight + cellSize / 2, cellSize / 2, cellSize / 2);
    }
}

/**
 * ナビゲーションバー
 */
void drawUI() {
    fill(220);
    rect(0, 0, width, navHeight);
    fill(0);
    textSize(20);
    textAlign(LEFT, CENTER);
    text("Player Oil: " + playerOil, 10, navHeight / 2);
    text("Enemy Oil: " + enemyOil, 200, navHeight / 2);

    textAlign(CENTER, CENTER);
    if (!gameStarted) {
        fill(100);
        rect(width - 150, 10, 140, navHeight - 20, 5); // Startボタンの背景
        fill(255);
        text("Start Simulation", width - 80, navHeight / 2);
    } else if (inputValue != -1) {
        text("Allocated: " + inputValue, width / 2, navHeight / 2);
    }
}

void updateCell() {
    // 次のフレームの状態を初期化
    for (int i = 0; i < cols; ++i) {
        for (int j = 0; j < rows; ++j) {
            nextGrid[i][j] = 0; // 一旦全て空にする
        }
    }

    // 原油の移動
    for (int i = 0; i < cols; ++i) {
        for (int j = 0; j < rows; ++j) {
            if (grid[i][j] == 1 || grid[i][j] == 2) { // アクティブな原油セルに関して
                ArrayList<PVector> emptyNeighbors = getEmptyNeighborsWithPotential(i, j, grid[i][j]);
                if (emptyNeighbors.size() > 0 && random(1) < D) { // 移動確率
                    PVector target = emptyNeighbors.get(floor(random(emptyNeighbors.size())));
                    nextGrid[(int) target.x][(int) target.y] = grid[i][j]; // 原油を移動
                } else {
                    nextGrid[i][j] = grid[i][j]; // 移動しない場合はそのまま
                }
            }
        }
    }

    // セルの塗り替え
    for (int i = 0; i < cols; ++i) {
        for (int j = 0; j < rows; ++j) {
            if (grid[i][j] == 1 || grid[i][j] == 2) {
                int allyCount = 0;
                int enemyCount = 0;
                for (int xOffset = -1; xOffset <= 1; xOffset++) {
                    for (int yOffset = -1; yOffset <= 1; yOffset++) {
                        if (xOffset == 0 && yOffset == 0) continue;
                        int ni = i + xOffset;
                        int nj = j + yOffset;
                        if (isValid(ni, nj)) {
                            if (grid[ni][nj] == 1) {
                                ++allyCount;
                            } else if (grid[ni][nj] == 2) {
                                ++enemyCount;
                            }
                        }
                    }
                }
                if (allyCount > 3 && grid[i][j] == 2) { // パラメータ調整
                    nextGrid[i][j] = 1; // 味方セルに変化
                } else if (enemyCount > 3 && grid[i][j] == 1) { // パラメータ調整
                    nextGrid[i][j] = 2; // 敵セルに変化
                }
            } else if (grid[i][j] >= 3) { // 拠点は維持
                nextGrid[i][j] = grid[i][j];
            }
        }
    }

    // 拠点の占領判定
    checkBaseCapture();

    // 拠点の原油分配
    for (int k = 0; k < bases.size(); k++) {
        int owner = baseOwners[k];
        if (owner == 1 || owner == 2) {
            int baseX = (int) bases.get(k).x;
            int baseY = (int) bases.get(k).y;
            if (baseOil[k] > 0) {
                int spreadAmount = min(baseOil[k], 5); // 一度に撒く量
                int count = 0;
                for (int i = baseX - 5; i <= baseX + 5; ++i) {
                    for (int j = baseY - 12; j <= baseY + 12; ++j) {
                        if (isValid(i, j) && grid[i][j] == 0 && count < spreadAmount && random(1) < 0.7) {
                            nextGrid[i][j] = owner;
                            baseOil[k]--;
                            count++;
                        }
                    }
                }
            }
        }
    }

    // グリッドを更新
    for (int i = 0; i < cols; ++i) {
        for (int j = 0; j < rows; ++j) {
            grid[i][j] = nextGrid[i][j];
        }
    }

    // 油田からの収入
    for (PVector oilField : oilFields) {
        int i = (int) oilField.x;
        int j = (int) oilField.y;
        int playerNeighbors = 0;
        int enemyNeighbors = 0;
        for (int xOffset = -1; xOffset <= 1; xOffset++) {
            for (int yOffset = -1; yOffset <= 1; yOffset++) {
                int ni = i + xOffset;
                int nj = j + yOffset;
                if (isValid(ni, nj)) {
                    if (grid[ni][nj] == 1) playerNeighbors++;
                    else if (grid[ni][nj] == 2) enemyNeighbors++;
                }
            }
        }
        if (playerNeighbors > enemyNeighbors) {
            playerOil++;
        } else if (enemyNeighbors > playerNeighbors) {
            enemyOil++;
        }
    }
}

void checkBaseCapture() {
    for (int k = 0; k < bases.size(); k++) {
        int baseX = (int) bases.get(k).x;
        int baseY = (int) bases.get(k).y;
        int owner = baseOwners[k];
        if (owner != 0) {
            int ownedCount = 0;
            for (int xOffset = -1; xOffset <= 1; xOffset++) {
                for (int yOffset = -1; yOffset <= 1; yOffset++) {
                    if (xOffset == 0 && yOffset == 0) continue;
                    int ni = baseX + xOffset;
                    int nj = baseY + yOffset;
                    if (isValid(ni, nj) && grid[ni][nj] == owner) {
                        ownedCount++;
                    }
                }
            }
            // if (ownedCount < 3) { // 周囲に自陣のセルが少ない場合は中立化
            //     baseOwners[k] = 0;
            // }
        } else { // 中立拠点の占領判定
            int playerNeighbors = 0;
            int enemyNeighbors = 0;
            for (int xOffset = -1; xOffset <= 1; xOffset++) {
                for (int yOffset = -1; yOffset <= 1; yOffset++) {
                    if (xOffset == 0 && yOffset == 0) continue;
                    int ni = baseX + xOffset;
                    int nj = baseY + yOffset;
                    if (isValid(ni, nj)) {
                        if (grid[ni][nj] == 1) playerNeighbors++;
                        else if (grid[ni][nj] == 2) enemyNeighbors++;
                    }
                }
            }
            if (playerNeighbors >= 5) {
                baseOwners[k] = 1;
            } else if (enemyNeighbors >= 5) {
                baseOwners[k] = 2;
            }
        }
    }
}

/**
 * ポテンシャルを考慮した空き隣接セルを取得
 */
ArrayList<PVector> getEmptyNeighborsWithPotential(int x, int y, int owner) {
    ArrayList<PVector> neighbors = new ArrayList<>();
    float currentPotential = potential[x][y];
    for (int xOffset = -1; xOffset <= 1; xOffset++) {
        for (int yOffset = -1; yOffset <= 1; yOffset++) {
            if (xOffset == 0 && yOffset == 0) continue;
            int nx = x + xOffset;
            int ny = y + yOffset;
            if (isValid(nx, ny) && grid[nx][ny] == 0) {
                float nextPotential = potential[nx][ny];
                // ポテンシャルが低い方へ移動する確率を上げる
                if (owner == 1 && nextPotential < currentPotential || owner == 2 && nextPotential > currentPotential) {
                    neighbors.add(new PVector(nx, ny));
                } else if (random(1) < 0.1) { // 低い方へもわずかな確率で移動
                    neighbors.add(new PVector(nx, ny));
                }
            }
        }
    }
    return neighbors;
}

/**
 * @return 隣接する空セルの数
 */
ArrayList<PVector> getEmptyNeighbors(int x, int y) {
    ArrayList<PVector> neighbors = new ArrayList<>();
    for (int xOffset = -1; xOffset <= 1; xOffset++) {
        for (int yOffset = -1; yOffset <= 1; yOffset++) {
            if (xOffset == 0 && yOffset == 0) continue;
            int nx = x + xOffset;
            int ny = y + yOffset;
            if (isValid(nx, ny) && grid[nx][ny] == 0) {
                neighbors.add(new PVector(nx, ny));
            }
        }
    }
    return neighbors;
}

void mousePressed() {
    for (int i = 0; i < bases.size(); ++i) {
        float bx = bases.get(i).x * cellSize;
        float by = bases.get(i).y * cellSize + navHeight;
        if (mouseX > bx && mouseX < bx + cellSize && mouseY > by && mouseY < by + cellSize) {
            // ゲーム開始前、または所有している拠点の場合のみ操作可能
            if (!gameStarted || baseOwners[i] == 1) {
                baseOwners[i] = 1;
                String message = "割り当てる原油数を入力してください (所持数: " + playerOil + ", 拠点原油: " + baseOil[i] + "):";
                String input = JOptionPane.showInputDialog(message);
                try {
                    if (input != null) {
                        int amount = Integer.parseInt(input);
                        if (amount > 0 && playerOil >= amount) {
                            playerOil -= amount;
                            baseOil[i] += amount;
                            inputValue = amount;
                        } else {
                            println("無効な入力または原油が不足しています。");
                        }
                    }
                } catch (NumberFormatException e) {
                    println("数字ではありません: " + input);
                }
                inputValue = -1; // 入力後リセット
            }
            break;
        }
    }

    if (!gameStarted) {
        // Startボタンがクリックされたか確認
        if (mouseX > width - 150 && mouseX < width - 10 && mouseY > 10 && mouseY < navHeight - 10) {
            //enemyTurn();
            gameStarted = true;
            return;
        }
    }
}

void allocateOil(int baseIndex, int owner, int amount) {
    baseOwners[baseIndex] = owner;
    baseOil[baseIndex] += amount;
}

void enemyTurn() {
    if (!gameStarted) { // ゲーム開始前はフリーな拠点に分配
        ArrayList<Integer> neutralBases = new ArrayList<>();
        for (int i = 0; i < bases.size(); ++i) {
            if (baseOwners[i] == 0) {
                neutralBases.add(i);
            }
        }
        if (neutralBases.size() > 0 && enemyOil > 0) {
            int selectedBaseIndex = neutralBases.get(floor(random(neutralBases.size())));
            int amount = floor(random(min(enemyOil, 20))) + 10;
            if (amount > 0) {
                enemyOil -= amount;
                allocateOil(selectedBaseIndex, 2, amount);
            }
        }
    } else { // ゲーム開始後は占領している拠点に分配
        ArrayList<Integer> enemyBases = new ArrayList<>();
        for (int i = 0; i < bases.size(); ++i) {
            if (baseOwners[i] == 2) {
                enemyBases.add(i);
            }
        }
        if (enemyBases.size() > 0 && enemyOil > 0) {
            int selectedBaseIndex = enemyBases.get(floor(random(enemyBases.size())));
            int amount = floor(random(min(enemyOil, 15))) + 5;
            if (amount > 0) {
                enemyOil -= amount;
                baseOil[selectedBaseIndex] += amount;
            }
        }
    }
}

boolean isValid(int i, int j) {
    return i >= 0 && i < cols && j >= 0 && j < rows;
}

void checkWinCondition() {
    boolean playerWins = true;
    boolean enemyWins = true;
    for (int owner : baseOwners) {
        if (owner != 1) {
            playerWins = false;
        }
        if (owner != 2) {
            enemyWins = false;
        }
    }

    if (playerWins) {
        println("Player wins!");
        gameStarted = false;
        noLoop();
    } else if (enemyWins) {
        println("Enemy wins!");
        gameStarted = false;
        noLoop();
    }
}
