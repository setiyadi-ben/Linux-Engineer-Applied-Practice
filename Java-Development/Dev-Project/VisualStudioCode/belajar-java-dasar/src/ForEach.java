public class ForEach {
    public static void main(String[] args) {

        /*
         - For each digunakan untuk mengambil data array sebagai
         alternatif untuk menggantikan for i loop yang bertele-tele
         (karena harus membuat counter terhadap data array tersebut)
         */

        // sampel data array
         String[] names = {
            "Eko", "Kurniawan", "Khannedy",
            "Programmer", "Zaman", "Now"
        };
        
        // contoh for i loop yang bertele-tele
        for (var i = 0; i< names.length; i++){
            System.out.println(names[i]);
        }

        // contoh for each yang lebih singkat
        for(var name: names){
            System.out.println(name);
        }
    }


}
