import javax.swing.JOptionPane;

int inputValue = -1; // 初期値を設定
int boxX = 100; // 使わない
int boxY = 100; // 使わない
int boxSize = 50; // 使わない

int cols, rows;  // グリッドの列数と行数
int cellSize = 10;  // セルのサイズを大きく
float D = 0.8;  // 拡散係数（0～1）を調整
int[][] grid, nextGrid;  // 現在のグリッドと次の状態を保持するグリッド

int navHeight = 50; // ナビゲーションバーの高さ
int playerOil = 100;
int enemyOil = 100;

// 拠点の座標と所有者（0: なし, 1: プレイヤー, 2: 敵）
ArrayList<PVector> bases = new ArrayList<>();
int[] baseOwners;

// 油田の座標
ArrayList<PVector> oilFields = new ArrayList<>();

void setup() {
    size(1080, 720);
    cols = width / cellSize;
    rows = (height - navHeight) / cellSize;

    grid = new int[cols][rows];
    nextGrid = new int[cols][rows];

    // 拠点の初期配置
    bases.add(new PVector(cols / 4, rows / 4));
    bases.add(new PVector(cols * 3 / 4, rows * 3 / 4));
    bases.add(new PVector(cols / 4, rows * 3 / 4));
    bases.add(new PVector(cols * 3 / 4, rows / 4));
    baseOwners = new int[bases.size()]; // 初期状態は所有者なし

    // 油田のランダム配置
    for (int i = 0; i < 10; i++) {
        oilFields.add(new PVector(floor(random(cols)), floor(random(navHeight, rows))));
    }

    // グリッドの初期化（拠点を設定）
    for (int i = 0; i < bases.size(); i++) {
        grid[(int) bases.get(i).x][(int) bases.get(i).y] = 3 + i; // 3, 4, 5, 6 を拠点としてマーク
    }
}

void draw() {
    background(240);
    drawGrid();  // グリッドを描画
    drawUI();    // UIを描画
    updateCell();  // グリッドを更新
    checkWinCondition(); // 勝利条件のチェック

    // 敵のターンを一定間隔で実行 (簡易的なAI)
    if (frameCount % 60 == 0) {
        enemyTurn();
    }
}

void drawGrid() {
    for (int i = 0; i < cols; i++) {
        for (int j = navHeight; j < rows; j++) {
            if (grid[i][j] == 1) {
                fill(10, 10, 10); // プレイヤーの原油は黒
            } else if (grid[i][j] == 2) {
                fill(200, 0, 0); // 敵の原油は赤
            } else if (grid[i][j] >= 3 && grid[i][j] <= 6) {
                int baseIndex = grid[i][j] - 3;
                if (baseOwners[baseIndex] == 1) {
                    fill(0, 0, 150); // プレイヤーの拠点
                } else if (baseOwners[baseIndex] == 2) {
                    fill(150, 0, 0); // 敵の拠点
                } else {
                    fill(150);      // 中立の拠点
                }
            } else {
                fill(255);  // 空セルは白
            }
            strokeWeight(0.2);
            stroke(200);
            rect(i * cellSize, j * cellSize, cellSize, cellSize);
        }
    }

    // 油田を描画
    fill(255, 200, 0); // 黄色
    for (PVector oilField : oilFields) {
        ellipse(oilField.x * cellSize + cellSize / 2, oilField.y * cellSize + cellSize / 2, cellSize / 2, cellSize / 2);
    }
}

void drawUI() {
    fill(220);
    rect(0, 0, width, navHeight);
    fill(0);
    textSize(20);
    textAlign(LEFT, CENTER);
    text("Player Oil: " + playerOil, 10, navHeight / 2);
    text("Enemy Oil: " + enemyOil, 200, navHeight / 2);

    textAlign(CENTER, CENTER);
    if (inputValue != -1) {
        text("Allocated: " + inputValue, width / 2, navHeight / 2);
    }
}

void updateCell() {
    // グリッドのコピー
    for (int i = 0; i < cols; i++) {
        for (int j = navHeight; j < rows; j++) {
            nextGrid[i][j] = grid[i][j];
        }
    }

    // 状態更新
    for (int i = 0; i < cols; i++) {
        for (int j = navHeight; j < rows; j++) {
            int playerNeighborCount = 0;
            int enemyNeighborCount = 0;

            // 周囲8マスの彼我セルをカウント
            for (int xOffset = -1; xOffset <= 1; xOffset++) {
                for (int yOffset = -1; yOffset <= 1; yOffset++) {
                    if (xOffset == 0 && yOffset == 0) continue;
                    int ni = (i + xOffset + cols) % cols;
                    int nj = (j + yOffset + rows) % rows;
                    if (nj >= navHeight && nj < rows) {
                        if (grid[ni][nj] == 1) {
                            playerNeighborCount++;
                        } else if (grid[ni][nj] == 2) {
                            enemyNeighborCount++;
                        }
                    }
                }
            }

            // 原油の拡散
            if (grid[i][j] == 0) {
                if (playerNeighborCount > enemyNeighborCount && random(1) < D) {
                    nextGrid[i][j] = 1;
                } else if (enemyNeighborCount > playerNeighborCount && random(1) < D) {
                    nextGrid[i][j] = 2;
                }
            }
        }
    }

    // グリッドを更新
    for (int i = 0; i < cols; i++) {
        for (int j = navHeight; j < rows; j++) {
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
                int ni = (i + xOffset + cols) % cols;
                int nj = (j + yOffset + rows) % rows;
                if (nj >= navHeight && nj < rows) {
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

void mousePressed() {
    for (int i = 0; i < bases.size(); i++) {
        float bx = bases.get(i).x * cellSize;
        float by = bases.get(i).y * cellSize;
        if (mouseX > bx && mouseX < bx + cellSize && mouseY > by && mouseY < by + cellSize) {
            if (baseOwners[i] == 0 || baseOwners[i] == 1) { // 中立または自陣の拠点のみ操作可能
                String input = JOptionPane.showInputDialog("割り当てる原油数を入力してください (所持数: " + playerOil + "):");
                try {
                    if (input != null) {
                        int amount = Integer.parseInt(input);
                        if (amount > 0 && playerOil >= amount) {
                            playerOil -= amount;
                            inputValue = amount;
                            allocateOil(i, 1, amount); // プレイヤーが油を割り当てる
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
}

void allocateOil(int baseIndex, int owner, int amount) {
    int baseX = (int) bases.get(baseIndex).x;
    int baseY = (int) bases.get(baseIndex).y;

    // 拠点の所有者を設定
    baseOwners[baseIndex] = owner;

    // 拠点の周囲に原油を配置
    for (int i = baseX - 2; i <= baseX + 2; i++) {
        for (int j = baseY - 2; j <= baseY + 2; j++) {
            if (random(1) < 0.5 && isValid(i, j)) { // ランダムに配置
                grid[i][j] = owner;
            }
        }
    }
}

void enemyTurn() {
    // ランダムに拠点を一つ選び、原油を割り当てる
    ArrayList<Integer> enemyBases = new ArrayList<>();
    for (int i = 0; i < bases.size(); i++) {
        if (baseOwners[i] == 0 || baseOwners[i] == 2) {
            enemyBases.add(i);
        }
    }

    if (enemyBases.size() > 0 && enemyOil > 0) {
        int selectedBaseIndex = enemyBases.get(floor(random(enemyBases.size())));
        int amount = floor(random(enemyOil / enemyBases.size() + 1)); // 分散して割り当てる
        if (amount > 0) {
            enemyOil -= amount;
            allocateOil(selectedBaseIndex, 2, amount);
        }
    }
}

boolean isValid(int i, int j) {
    return i >= 0 && i < cols && j >= navHeight && j < rows;
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
        noLoop();
    } else if (enemyWins) {
        println("Enemy wins!");
        noLoop();
    }
}
// content_copy
// download
// Use code with caution.
// Processing

// 主な変更点:

// ゲーム概要に合わせた変数名と初期値:

// inputValue, boxX, boxY, boxSize は、元のクリック操作に関連するものなので、今回のゲームではほとんど使用しません。

// cellSize を大きくして、グリッドを見やすくしました。

// D (拡散係数) を調整しました。

// navHeight を増やして、UI表示スペースを確保しました。

// playerOil と enemyOil でそれぞれの持ち原油数を管理します。

// 拠点の管理:

// bases: ArrayList<PVector> で拠点の座標を保持します。

// baseOwners: int[] で各拠点の所有者（0: なし, 1: プレイヤー, 2: 敵）を管理します。

// 初期配置でいくつかの拠点をマップ上に設定しています。

// 油田の管理:

// oilFields: ArrayList<PVector> で油田の座標を保持します。

// setup() でランダムに油田を配置しています。

// drawGrid() の変更:

// 拠点を異なる色で描画するようにしました（中立、プレイヤー所有、敵所有）。

// 油田を黄色の円で描画するようにしました。

// drawUI() の追加:

// 画面上部にナビゲーションバーを表示し、プレイヤーと敵の原油数を表示します。

// 原油割り当て時のメッセージもここに表示するように変更しました。

// updateCell() の変更:

// 原油の拡散ロジックを、隣接するプレイヤーまたは敵の原油の数に基づいて、空セルがどちらかの陣営の原油に変わるように変更しました。

// 油田の周囲を占拠している陣営に、定期的に原油収入が入るようにしました。

// mousePressed() の変更:

// グリッド上の拠点をクリックすると、その拠点のインデックスを取得し、所有者がいないかプレイヤーの拠点であれば、原油割り当てのダイアログを表示するようにしました。

// allocateOil() の追加:

// 指定された拠点に、指定された陣営の原油を一定範囲にランダムに配置する処理を実装しました。

// 拠点の所有者を設定します。

// enemyTurn() の追加:

// 簡易的な敵のAIとして、ランダムに敵が所有または中立の拠点を一つ選び、ランダムな量の原油を割り当てる処理を実装しました。

// isValid() の追加:

// グリッドの範囲内かどうかを判定するヘルパー関数です。

// checkWinCondition() の追加:

// すべての拠点が単一の陣営の所有になったかどうかをチェックし、勝利メッセージを表示してゲームを停止します。

// 今後の拡張:

// より洗練された敵AI: 戦略的な原油の割り当てや、拠点の奪還を試みるAI。

// 特殊能力やアイテム: ゲームに深みを与える要素。

// UIの改善: より分かりやすく、操作しやすいインターフェース。

// アニメーションやエフェクト: 視覚的なフィードバックを向上させる。

// 難易度設定: 敵AIの強さや初期リソースなどを調整可能にする。

// このコードはまだ基本的なゲームの枠組みであり、必要に応じて機能を追加・調整していくことができます。

// content_copy
// download
// Use code with caution.