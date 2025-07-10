public class AplikasiTodoList {
    public static String[]model = new String[10];
    public static void main(String[] args) {
        testShowTodoList();
    }

    /*
     * SHOW, ADD, REMOVE TODOLIST
     */
    // Menampilkan todolist
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
    // public static void testShowTodoList() {
    //     model[0]="Belajar Java Dasar";
    //     model[1]="Studi Kasus Java Dasar : Aplikasi TodoList";
    //     showTodoList();
        
    // }

    // menambah "todo" kedalam list
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
     * TEST SHOW
     * TEST ADD
     */
    public static void testShowTodoList(){
        // from TEST SHOW
        model[0]="Belajar Java Dasar";
        model[1]="Studi Kasus Java Dasar : Aplikasi TodoList";
        // showTodoList();
        for (int i=0; i<25; i++){
            addTodoList("Contoh Todo Ke-" +i);
        }
        showTodoList();
    }


    // menghapus "todo" kedalam list
    public static void removeTodoList(){

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
