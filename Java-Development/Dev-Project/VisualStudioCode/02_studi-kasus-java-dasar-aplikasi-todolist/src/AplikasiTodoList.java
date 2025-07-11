public class AplikasiTodoList {
    public static String[]model = new String[10];
    public static void main(String[] args) {
        //testShowTodoList();
        //testAddTodoList();
        testRemoveTodoList();
    }

    /*
     * SHOW, ADD, REMOVE TODOLIST
     */
    // (SHOW) | Menampilkan todolist
    public static void showTodoList(){

        for (var i=0; i<model.length; i++){
            //var todo:String=model[i]; //Cannot use 'var' on variable without initializer
            // Jangan ditulis begitu, ditulis begini var todo=model[i]; atau seperti dibawah ini:
            String todo=model[i];
            var no=i+1;

            if (todo!=null){
                // System.out.println(no + "." + todo); // Masalah "." yang didalamnya kurang spasi menjadi ". "
                System.out.println(no + ". " + todo);
            }
        }

    }
    /*
     *  TEST SHOW
     */
    public static void testShowTodoList() {
        model[0]="Belajar Java Dasar";
        model[1]="Studi Kasus Java Dasar : Aplikasi TodoList";
        showTodoList();
    }

    // (ADD) | menambah "todo" kedalam list
    public static void addTodoList(String todo){
        // Cek apakah model penuh?
        var isFull=true;
        for (int i=0; i<model.length; i++){
            if (model[i]==null){
                // Jika terdapat model ysng masih kosong
                // 
                isFull=false;
                break;
            }
        }
        // Jika penuh, kita resize ukuran array 2x lipat
        if (isFull){
            var temp=model;
            model=new String[model.length*2];

            for (int i=0; i<temp.length; i++){
                model[i]=temp[i];
            }
        }
        // Tambahkan ke posisi data index array yang masih NULL
        for (var i=0; i<model.length; i++){
            if (model[i]==null){
                model[i]=todo;
                break;
            }
        }
    }
    /*
     * TEST ADD
     */
    public static void testAddTodoList(){
        // from TEST SHOW
        model[0]="Belajar Java Dasar";
        model[1]="Studi Kasus Java Dasar : Aplikasi TodoList";
        // showTodoList();
        for (int i=0; i<25; i++){
            addTodoList("Contoh Todo Ke-" +i);
        }
        showTodoList();
    }


    // (REMOVE) | menghapus "todo" kedalam list
    public static boolean removeTodoList(Integer number){ // void diganti boolean untuk memunculkan hasil pengecekan dalam kondisi true | false
        if ((number-1)>=model.length){
            // mengecek apakah index data array (nilai model) sesuai atau lebih dari batas 
            // Index dimulai dari 0 | nilai index array yang termasuk ialah 10, 11, 12, ..., |karena public static String[]model = new String[10];
            return false;            
        }else if (model[number-1]==null){ 
            // mengecek apakah slot index array yang ingin dihapus sudah kosong
            return false;
        }else{ // geser index array ke atas (nilai yang lebih rendah) | berlaku jika index bernilai 9, 8, 7, ...,s/d 0
            /*
             1. Loop dimulai dari index target (number-1)
             2. Geser semua elemen setelahnya ke atas (nilai yang lebih rendah) 
             3. Set index terakhir menjadi null
             */
            for (int i=(number-1); i<model.length; i++){
                // perulangan untuk mengecek apakah nilai "i" adalah nilai index array yang masuk dalam kategori <model.length yaitu nilai 9 kebawah.
                if (i==model.length-1){ 
                    // jika nilai "i" masuk kategori, set index array "i" menjadi null atau kosong
                    // misalkan model i=2 maka model[2]cakan dihapus,  
                    /*
                     baca line 125
                     dimana angka yang dipilih var result3=removeTodoList(2); akan menghapus addTodoList("Dua"); menjadi null
                     */
                    model[i]=null;
                }else{
                    // jika nilai "i" tidak masuk kategori, tambahkan nilai index array dengan "1"
                    model[i]=model[i+1];
                }
            }
            return true;
        }
    }

    public static void testRemoveTodoList(){
        addTodoList("Satu");
        addTodoList("Dua");
        addTodoList("Tiga");
        addTodoList("Empat");
        addTodoList("Lima");

        var result=removeTodoList(20);
        System.out.println(result); // false (out of bounds/batas) | if ((number-1)>=model.length){}

        var result2=removeTodoList(7);
        System.out.println(result2); // false (slot empty) | else if (model[number-1]==null){}

        var result3=removeTodoList(2);
        System.out.println(result3); // true (success)
        /* berasal dari line 91 | data dari line 111 hingga 115
          else{} dimana,
          for (int i=(number-1); i<model.length; i++) mendeteksi angka "2" masuk dalam kategori index
           yang aslinya model 2 adalah 1 (0=null,1=satu,2=dua) karena model[i]=model[i+1] menjadi index 3 yaitu "Dua" yang dihilangkan dan 
           "Tiga" naik ke index 3 menjadi 3 dari yang semula 
           (0=null,1=satu,2=dua,3=tiga,4=empat,5=lima) menjadi (0=null,1=satu,2=tiga,3=empat,4=lima,5=null)
         */

        showTodoList();
    }

    /*
     * VIEWS ATAU TAMPILAN DARI TODOLIST
     */

    // Menampilkan tampilan todolist
    public static void viewTodoList(){

    }

     // Menampilkan tampilan addTodoList
    public static void viewAddTodoList(){

    }

    // Menampilkan tampilan removeTodoList
    public static void viewRemoveTodoList(){

    }

}
