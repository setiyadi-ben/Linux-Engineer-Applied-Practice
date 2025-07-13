public class AplikasiTodoList {
    // Array penyimpanan todo dengan kapasitas awal 10
    public static String[] model = new String[10];
    
    public static void main(String[] args) {
        testRemoveTodoList(); // Jalankan tes penghapusan todo
    }

    /*
     * SHOW, ADD, REMOVE TODOLIST
     */
    // (SHOW) | Menampilkan seluruh todo yang ada
    public static void showTodoList(){
        /*
         * PROSES:
         * 1. Iterasi melalui setiap index array model
         * 2. Untuk setiap item yang tidak null:
         *    - Tampilkan nomor urut (index + 1)
         *    - Tampilkan teks todo
         */
        for (var i = 0; i < model.length; i++) {
            String todo = model[i];  // Ambil nilai di index saat ini
            var no = i + 1;          // Nomor urut dimulai dari 1

            if (todo != null) {
                // Format: "1. Belajar Java"
                System.out.println(no + ". " + todo); 
            }
        }
    }

    // (ADD) | Menambahkan todo baru ke dalam list
    public static void addTodoList(String todo) {
        /*
         * PROSES:
         * 1. Cek apakah array sudah penuh (tidak ada null)
         * 2. Jika penuh: 
         *    - Buat array baru 2x ukuran saat ini
         *    - Salin semua data ke array baru
         * 3. Cari slot kosong pertama (null)
         * 4. Isi slot tersebut dengan todo baru
         */
        var isFull = true;
        for (int i = 0; i < model.length; i++) {
            if (model[i] == null) {
                isFull = false; // Ditemukan slot kosong
                break;
            }
        }
        
        // Handle array penuh
        if (isFull) {
            var temp = model; // Simpan referensi array lama
            model = new String[model.length * 2]; // Buat array baru
            
            // Salin data dari array lama ke baru
            for (int i = 0; i < temp.length; i++) {
                model[i] = temp[i];
            }
        }
        
        // Tambahkan ke slot kosong pertama
        for (var i = 0; i < model.length; i++) {
            if (model[i] == null) {
                model[i] = todo; // Isi slot kosong
                break; // Hentikan pencarian setelah ditemukan
            }
        }
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
         */
        // Validasi 1: Index di luar batas array [0..length-1]
        if ((number - 1) >= model.length) {
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

    // TEST: Simulasi penghapusan todo
    public static void testRemoveTodoList() {
        // Setup data uji
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
     */
    public static void viewTodoList() {}
    public static void viewAddTodoList() {}
    public static void viewRemoveTodoList() {}
}