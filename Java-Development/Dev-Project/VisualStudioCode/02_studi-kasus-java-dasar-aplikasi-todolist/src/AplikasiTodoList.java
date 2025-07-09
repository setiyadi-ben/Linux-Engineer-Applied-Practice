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
            String todo=model[i];
            var no=i+1;

            if (todo!=null){
                // System.out.println(no + "." + todo); // Masalah "." yang didalamnya kurang spasi menjadi ". "
                System.out.println(no + ". " + todo);
            }
        }

    }

    /*
     *  TEST SHOW, ADD, DELETE TODOLIST
     */
    public static void testShowTodoList() {
        model[0]="Belajar Java Dasar";
        model[1]="Studi Kasus Java Dasar : Aplikasi TodoList";
        showTodoList();
        
    }

    // menambah "todo" kedalam list
    public static void addTodoList(){

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
