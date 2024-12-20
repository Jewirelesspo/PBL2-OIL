import javax.swing.JOptionPane;

int inputValue = -1; // 初期値を設定
int boxX = 100; // クリック対象のボックスの位置
int boxY = 100;
int boxSize = 50; // ボックスの大きさ

int cols, rows;  // グリッドの列数と行数
int cellSize = 5;  // セルのサイズ
float D = 0.4;  // 拡散係数（0～1）
int[][] grid, nextGrid;  // 現在のグリッドと次の状態を保持するグリッド

int navHeight = 10;

// int alignedHeight = height - 20;

void setup() {
    size(1080, 720);
    cols = width / cellSize;
    rows = (height - navHeight) / cellSize;
    
    grid = new int[cols][rows];
    nextGrid = new int[cols][rows];
    
    //グリッドの初期化（ランダムにセルを配置）
    for (int i = cols / 4 - 10; i < cols / 4 + 10; ++i) {
        for (int j = rows / 4 - 10; j < rows / 4 + 10; ++j) {
            grid[i][j] = random(1) < 0.5 ? 1 : 0;  // 初期状態
        }
    }
    
    for (int i = cols * 3 / 4 - 10; i < cols * 3 / 4 + 10; ++i) {
        for (int j = rows * 3 / 4 - 10; j < rows * 3 / 4 + 10; ++j) {
            grid[i][j] = random(1) < 0.5 ? 2 : 0;  // 初期状態
        }
    }
}

void draw() {
    background(255);
    drawGrid();  // グリッドを描画
    updateCell();  // グリッドを更新
}

void drawGrid() {
    for (int i = 0; i < cols; i++) {
        for (int j = navHeight; j < rows; j++) {
            if (grid[i][j] == 1) {
                fill(10, 10, 10);// アクティブセルは黒
            } else if (grid[i][j] == 2) {
                fill(200, 0, 0);
            } else{
                fill(255);  // 空セルは白
            }
            strokeWeight(0.5);
            stroke(220);
            rect(i * cellSize, j * cellSize, cellSize, cellSize);
        }
    }
    
    fill(150, 200, 250);
    rect(boxX, boxY, boxSize, boxSize);
    
    //入力された数字を表示
    fill(0);
    textSize(22);
    textAlign(CENTER, CENTER);
    if (inputValue != -1) {
        text("Input: " + inputValue, width / 2, height - 50);
    } else {
        text("Click the box", width / 2, height - 50);
    }
    
    textSize(30);
    textAlign(RIGHT, TOP);
    text("Oil: " + 20, width, 0);
}

void updateCell() {
    //状態更新
    for (int i = cols - 1; i >= 0; i--) {
        for (int j = navHeight; j < rows; j++) {
            int allyCount = 0;
            int enemyCount = 0;
            
            // 周囲8マスの彼我セルをカウント
            for (int[] dir : new int[][]{{ - 1, -1} , { - 1, 0} , { - 1, 1} , {1, -1} , {1, 0} , {1, 1} , {0, -1} , {0, 1} }) {
                int ni = (i + dir[0] + cols) % cols; // x方向の移動
                int nj = (j + dir[1] + rows) % rows; // y方向の移動
                
                if (grid[ni][nj] == 1) {
                    ++allyCount;
                } else if (grid[ni][nj] == 2) {
                    ++enemyCount;
                }
            }
            
            // 次の状態を決定
            if (grid[i][j] == 0) { // 空セルの場合
                if (allyCount > 4) {
                    nextGrid[i][j] = 1; // 味方セルに変化
                } else if (enemyCount > 4) {
                    nextGrid[i][j] = 2; // 敵セルに変化
                } else {
                    nextGrid[i][j] = 0; // 状態を維持
                }
            } else if (grid[i][j] > 0) { // アクティブセルの場合
                nextGrid[i][j] = grid[i][j]; // 現在の状態を維持
                
                // 拡散処理 (ランダムに全方向へ分散)
                for (int[] dir : new int[][]{{ - 1, 0} , {1, 0} , {0, -1} , {0, 1} }) {
                    int ni = (i + dir[0] + cols) % cols; // x方向への移動処理
                    int nj = (j + dir[1] + rows) % rows; // y方向への移動処理
                    
                    if (random(1) < D / 4) { // 遷移が決まった場合
                        nextGrid[ni][nj] = grid[i][j]; // 拡散先をアクティブにする
                    }
                }
            }
        }
    }
    
    // グリッドを更新
    for (int i = 0; i < cols; ++i) {
        for (int j = navHeight; j < rows; ++j) {
            grid[i][j] = nextGrid[i][j];
        }
    }
}


void mousePressed() {
    //マウスがボックス内をクリックした場合
    if (mouseX > boxX && mouseX < boxX + boxSize && mouseY > boxY && mouseY < boxY + boxSize) {
        // 入力ダイアログを表示
        String input = JOptionPane.showInputDialog("数字を入力してください:");
        try {
            if (input!= null) { // キャンセルが押されなかった場合
                inputValue = Integer.parseInt(input); // 入力を整数に変換
            }
        } catch(NumberFormatException e) {
            println("数字ではありません: " + input);
        }
    }
}
