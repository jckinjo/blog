---
title: "計算機底層的秘密"
author: "Me"
showToc: true
comments: false
booknote: true
---

## Ch2. 程序運行

### 操作系統，進程與線程

- Program Counter
  - 約等於容量小但速度快的內存
  - 存放CPU即將執行的指令的內存地址
  - 想要讓程序運行起來需要把main的第一條指令寫入PC
- 讓CPU執行程序
  - 在內存中找到一塊大小合適的區域裝入程序
  - CPU寄存器初始化後，找到函數入口設置Program Counter寄存器
- 手動複製太繁瑣，用Loader把程序加載到內存
- 但是如果要在多個程序間切換就需要context，Process用於紀錄這些context
- 用於管理Loader, Process的程序叫做Operating System
- 如果兩個函數的執行是獨立的，可以創建多個進程
  - 但是開銷大
  - 由於進程有自己的地址空間，通信上較為複雜
- PC可以指向任意一個函數讓CPU共享地址空間，執行同一個進程的指令
  - 一個進程可以有多個執行流，也就是Thread
- Thread
  - 線程是操作系統層面的實現，跟有多少個核心沒用直接關係
  - 創建線程需要消耗內存空間
  - 為了減少創建與銷毀的頻率，引入Thread Pool
  - 根據應用的不同，Thread Pool中的Thread數量也不同

### 線程間共享了哪些進程資源

- stack私有的
  - 但是無保護機制
- Read Only的代碼區是共享的
  - 任何一個函數都可以放到線程中執行
- 數據區是共享的
  - 所有的線程都可以訪問 global variables
- Heap是共享的
  - 只要知道變量的地址，任何一個線程都可以訪問該地址指向的數據
- 動態庫中的代碼和數據也是共享的
- Thread Local Storage

### 線程安全

- 問題主要會發生在Heap與數據區
- 如何實現
  - Thread Local Storage
  - Read Only
  - 原子操作
  - 同步互斥

### Coroutine

- Coroutine返回後，runtime的信息是被保存下來的
- Coroutine的目的：以同步的方式進行異步編程

### 徹底理解回調函數 callback

- 從計算機的角度來講，信息有兩類
  - 數據：整數，指針，結構體，對象
  - 代碼：函數
- 調用函數時不但可以傳遞數據，也可以傳遞代碼
- callback
  - 函數編寫放是我們自己
  - 調用方是其他模塊
  - 調用方可能是在另一個線程，進程，甚至是另一台機器上完成
- 回調類型
  - Synchronous Callbacks, Blocking Callbacks
  - Asynchronous Callbacks, Deferred Callbacks

### Synchronous vs. Asynchronous

- 同步調用與調用方和被調用方是否運行在同一線程沒用關係
- 異步回調有兩種情況
  - 調用方不關心執行結果
  - 調用方需要知道執行結果

### Blocking vs. Non-blocking

- 阻塞一般都跟IO有關
  - CPU的處理速度 > 磁盤IO
  - 線程因IO操作被阻塞，CPU就會被分配到另一個線程
- 同步與阻塞
  - 阻塞 => 同步
- 異步與非阻塞
  - 同步也可以是非阻塞的，比如點了外送之後一直催單

### 融會貫通

- 多進程
  - 地址空間相互隔離，能充分利用多核資源
  - 進程間通信困難，創建開銷大
- 多線程
  - 直接讀取內存，無需通信機制。創建開銷相對小
  - 一個線程崩潰會導致整個進程崩潰
  - 用戶規模不大能應付來
- Event-based concurrency
  - 用epoll實現IO多路復用
  - Rector: 把事件循環和事件處理函數放到不同的線程
  - 運用Coroutine能兼顧，異步的高效和同步的簡單易懂
    - Coroutine本質上是CPU時間片在user space的二次分配

## Ch3 Memory

### 內存的本質

- 存放0和1的儲物櫃
- 指針是對內存地址的抽象，引用是對指針的進一步抽象
- 只要維護好虛擬內存地址到物理內存地址的映射關係，就不需要關心數據到底存在物理內存的哪個位置


### Stack: 函數調用

- 維護runtime的信息，函數的調用和返回就發生在這裡
- 保存函數runtime的各種信息的盒子稱為stack frame
- 參數傳遞與返回值
  - 被調用函數可以從前一個函數獲取參數
  - 局部變量也放在stack frame中

### Heap: 內存的動態分佈

- 需要程序員自己來維護生命週期
- 如果某個數據的使用需要跨過多個函數，但又不想用global var暴露給所有模塊
  - 內存的動態分佈：程序員自行決定什麼時候申請，多大，什麼時候無效
- 用鏈表形式管理內存塊
  - header: 31bit紀錄大小，1bit紀錄是否空閒
  - payload: 可供分配的內存塊
- 分配策略
  - First Fit
  - Next Fit
  - Best Fit
- 釋放內存
  - 將獲得的內存的首地址減去4byte就能獲得header的地址
  - 標註為空閒
- 如何高效合併內存塊
  - 在內存塊末尾加上footer
  - 從header減去4byte就能獲得上一個內存塊的footer
  - 合併也就變得簡單



### 內存分配器的實現

- 應用程式 -> 標準庫 -> 操作系統 -> 硬件
- malloc開始搜索，如有找到大小合適的就分配出去
- 找不到的話就利用brk進行system call擴大Heap
- malloc調用brk進入kernel mode，擴大虛擬內存
- brk結束後CPU從kernel轉回user mode，malloc進行分配後返回

### Memory Pool

- 自己申請一塊內存，繞過標準庫和操作系統
- 通用性比較差，用於特定場景
