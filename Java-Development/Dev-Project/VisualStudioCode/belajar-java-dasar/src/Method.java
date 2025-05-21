public class Method {
    public static void main(String[] args) {
        /*
         - Method merupakan block program yang akan berjalan saat dipanggil
         seperti "sayHelloWorld();"" merupakan representasi dari kode block "static void sayHelloWorld(){}"
         - Jika dipanggil melalui main method did dalam psvm "public static void main(){}""
         */
        sayHelloWorld();
        // method juga dapat dipanggil berulang
        sayHelloWorld();
    }

    static void sayHelloWorld(){
        System.out.println("Hello World 1");
        System.out.println("Hello World 2");
        System.out.println("Hello World 3");
    }
}
