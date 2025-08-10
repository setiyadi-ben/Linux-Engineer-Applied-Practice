public class AplikasiTodoList {
    // Array penyimpanan todo dengan kapasitas awal 10
    // NOTE: Array ini bersifat statis sehingga mempertahankan data selama aplikasi berjalan
    public static String[] model = new String[10];
    
    public static void main(String[] args) {
        /*
         * PUSAT KONTROL TES:
         * Uncomment salah satu test berikut sesuai kebutuhan pembelajaran:
         * 1. testShowTodoList()   : Demo menampilkan todo
         * 2. testAddTodoList()    : Demo menambah todo + auto resize
         * 3. testRemoveTodoList() : Demo menghapus todo + shifting array
         */
        // testShowTodoList();
        // testAddTodoList();
        testRemoveTodoList();
    }

    /*
     * SHOW, ADD, REMOVE TODOLIST
     * ===========================
     */

    // (SHOW) | Menampilkan seluruh todo yang ada
    public static void showTodoList(){
        /*
         * PROSES TAMPILAN:
         * 1. Iterasi melalui setiap index array model
         * 2. Untuk setiap item yang tidak null:
         *    - Tampilkan nomor urut (index + 1)
         *    - Tampilkan teks todo
         * 3. Item null diabaikan (tidak ditampilkan)
         */
        for (var i = 0; i < model.length; i++) {
            String todo = model[i];  // Ambil nilai di index saat ini
            var no = i + 1;          // Nomor urut dimulai dari 1 (bukan 0)

            if (todo != null) {
                // Format: "1. Belajar Java"
                // Spasi setelah titik penting untuk keterbacaan
                System.out.println(no + ". " + todo); 
            }
        }
    }

    /*
     * TEST SHOW: Demonstrasi fungsi tampilan
     * ======================================
     */
    public static void testShowTodoList() {
        /*
         * PROSES DEMO:
         * 1. Isi 2 data contoh
         * 2. Panggil showTodoList() untuk menampilkan hasil
         * 
         * HASIL YANG DIHARAPKAN:
         * 1. Belajar Java Dasar
         * 2. Studi Kasus Java Dasar : Aplikasi TodoList
         */
        model[0] = "Belajar Java Dasar";
        model[1] = "Studi Kasus Java Dasar : Aplikasi TodoList";
        showTodoList();
    }

    // (ADD) | Menambahkan todo baru ke dalam list
    public static void addTodoList(String todo) {
        /*
         * PROSES PENAMBAHAN:
         * 1. Cek apakah array sudah penuh (tidak ada slot null)
         * 2. Jika penuh: 
         *    - Simpan referensi array lama
         *    - Buat array baru 2x ukuran saat ini
         *    - Salin semua data ke array baru
         * 3. Cari slot kosong pertama (null)
         * 4. Isi slot tersebut dengan todo baru
         * 
         * ILUSTRASI RESIZE:
         * Kapasitas awal: 10 -> Penuh -> Resize jadi 20
         */
        // Step 1: Cek kapasitas
        var isFull = true;
        for (int i = 0; i < model.length; i++) {
            if (model[i] == null) { // Cek apakah ada slot kosong
                // Jika ada slot kosong, berarti array belum penuh
                isFull = false; // Set isFull ke false
                break;
            }
        }
        
        // Step 2: Resize jika penuh
        if (isFull) {
            var temp = model; // Simpan referensi array lama
            model = new String[model.length * 2]; // Buat array baru dengan kapasitas 2x
            
            // Salin data dari array lama ke baru
            for (int i = 0; i < temp.length; i++) {
                model[i] = temp[i];
            }
        }
        
        // Step 3-4: Cari slot kosong dan isi dengan todo baru
        for (var i = 0; i < model.length; i++) {
            if (model[i] == null) {
                model[i] = todo; // Isi slot kosong
                break; // Hentikan pencarian setelah ditemukan
            }
        }
    }

    /*
     * TEST ADD: Demonstrasi penambahan data + auto-resize
     * ===================================================
     */
    public static void testAddTodoList(){
        /*
         * PROSES DEMO:
         * 1. Isi 2 data awal (index 0 dan 1)
         * 2. Tambahkan 25 data baru (melebihi kapasitas awal 10)
         * 3. Tampilkan hasil untuk verifikasi:
         *    - Auto-resize otomatis terjadi
         *    - Data tetap utuh setelah resize
         */
        // Isi 2 data awal
        model[0] = "Belajar Java Dasar";
        model[1] = "Studi Kasus Java Dasar : Aplikasi TodoList";
        
        for (int i = 0; i < 25; i++) {
            addTodoList("Contoh Todo Ke-" + i);
        }
        
        showTodoList();
    }

    // (REMOVE) | Menghapus todo berdasarkan nomor urut
    public static boolean removeTodoList(Integer number) {
        /*
         * PROSES VALIDASI:
         * 1. Cek apakah nomor melebihi batas array:
         *    - Index = number-1 (konversi nomor urut ke index array)
         *    - Batas maksimal index = panjang array-1
         * 2. Cek apakah slot yang ingin dihapus sudah kosong
         * 
         * PROSES PENGHAPUSAN (jika validasi lolos):
         * 1. Mulai dari index target (number-1)
         * 2. Untuk setiap index dari target hingga akhir:
         *    - Jika index terakhir: set jadi null
         *    - Jika bukan: ganti nilai saat ini dengan nilai index berikutnya (shift left)
         * 
         * ILUSTRASI SHIFTING:
         * Sebelum: [A, B, C, D]
         * Hapus index 1 (B): 
         *   Iter1: [A, C, C, D] (index1 = index2)
         *   Iter2: [A, C, D, D] (index2 = index3)
         *   Iter3: [A, C, D, null] (index3 = null)
         */
        // Validasi 1: Index di luar batas array [0..length-1]
        if ((number - 1) >= model.length || number <= 0) {
            return false; // Index tidak valid
        }
        // Validasi 2: Slot sudah kosong
        else if (model[number - 1] == null) {
            return false; // Tidak ada data untuk dihapus
        }
        // PROSES PENGHAPUSAN
        else {
            /*
             * CONTOH KASUS: removeTodoList(2) pada data ["Satu","Dua","Tiga"]
             * - Index target: 1 (karena 2-1=1)
             * - Iterasi:
             *    i=1: model[1] = model[2] -> "Dua" diganti "Tiga"
             *    i=2: model[2] = null (karena i == length-1)
             * - Hasil: ["Satu","Tiga",null]
             */
            for (int i = (number - 1); i < model.length; i++) {
                if (i == model.length - 1) {
                    // Handle index terakhir: set null
                    model[i] = null;
                } else {
                    // Shift left: ganti nilai saat ini dengan nilai setelahnya
                    model[i] = model[i + 1];
                }
            }
            return true; // Penghapusan berhasil
        }
    }

    /*
     * TEST REMOVE: Demonstrasi penghapusan + shifting
     * ===============================================
     */
    public static void testRemoveTodoList() {
        /*
         * PROSES DEMO:
         * 1. Tambahkan 5 data contoh
         * 2. Uji 3 skenario penghapusan:
         *    a. Index diluar batas (20)
         *    b. Slot kosong (7)
         *    c. Penghapusan valid (2)
         * 3. Tampilkan hasil akhir untuk verifikasi shifting
         * 
         * HASIL YANG DIHARAPKAN:
         * - [0] Satu
         * - [1] Tiga (dulunya index 2)
         * - [2] Empat (dulunya index 3)
         * - [3] Lima  (dulunya index 4)
         * - [4] null
         */
        addTodoList("Satu");
        addTodoList("Dua");
        addTodoList("Tiga");
        addTodoList("Empat");
        addTodoList("Lima");

        // Test 1: Input diluar batas (harus false)
        var result = removeTodoList(20);
        System.out.println("Hapus index 20: " + result);
        
        // Test 2: Hapus slot kosong (harus false)
        var result2 = removeTodoList(7);
        System.out.println("Hapus slot 7: " + result2);
        
        // Test 3: Hapus valid (harus true)
        var result3 = removeTodoList(2);
        System.out.println("Hapus slot 2: " + result3);
        
        // Tampilkan hasil akhir
        System.out.println("\nDaftar setelah penghapusan:");
        showTodoList();
    }

    /*
     * VIEWS (TIDAK DIUBAH - IMPLEMENTASI FUTURE)
     * ===========================================
     * Catatan untuk implementasi masa depan:
     * 1. viewTodoList()      : UI untuk menampilkan daftar + navigasi
     * 2. viewAddTodoList()   : Form input untuk menambah todo
     * 3. viewRemoveTodoList(): Form pemilihan todo yang akan dihapus
     */
    public static void viewTodoList() {}
    public static void viewAddTodoList() {}
    public static void viewRemoveTodoList() {}
}