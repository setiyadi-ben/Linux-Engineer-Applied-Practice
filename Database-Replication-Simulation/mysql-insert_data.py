import mysql.connector
import datetime
import random
import time

mydb = mysql.connector.connect(
  host="192.168.129.129",
  port=3306,
  user="staff1-engineer",
  password="password",
  database="id-lcm-prd1"
)

# Define the lists of edible fish names
list_ikan = ["Ikan Gurame", "Ikan Lele", "Ikan Nila", "Ikan Patin", "Ikan Tuna"]
list_ikan.sort()

# Define price changes
list_price_changes_1 = [88550, 33000, 57200, 35200, 115610]
list_price_changes_2 = [88000, 32000, 58000, 33200, 110320]
list_price_changes_3 = [89250, 32500, 54000, 34450, 116000]
list_price_changes_4 = [87500, 33500, 56250, 35000, 114600]
list_price_changes_5 = [88500, 32300, 55700, 35800, 113500]
# Merge all price changes
all_price_changes = [list_price_changes_1, list_price_changes_2, list_price_changes_3, list_price_changes_4, list_price_changes_5]
# Function to simulate random pick selection
def random_pick_price_changes(lists):
    selected_price_list = random.choice(lists)  # Pick a random list
    return selected_price_list  # Return the selected list

# Simulate random pick selection
price_changes = random_pick_price_changes(all_price_changes)

#return select_list_ikan
stock_changes = [2099, 3548, 2545, 2200, 1800]

if __name__ == "__main__":
    mycursor = mydb.cursor()
    while True:
        # Define formatted_date as timestamp values
        now = datetime.datetime.now()
        formatted_date = now.strftime('%Y-%m-%d %H:%M:%S')

        for i in range(len(list_ikan)):
          sql = "INSERT INTO penjualan_ikan (name, timestamp, price, stock) VALUES (%s, %s, %s, %s)"
          val = ((list_ikan[i]), (formatted_date), (price_changes[i]), (stock_changes[i]))
          mycursor.execute(sql, val)
        
        mydb.commit()
        print(mycursor.rowcount, "was inserted.")
        # Looping
        time.sleep(60)