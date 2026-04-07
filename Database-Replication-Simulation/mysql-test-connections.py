import mysql.connector

mydb = mysql.connector.connect(
  host="192.168.129.129",
  port=3306,
  user="staff1-engineer",
  password="password",
)

print(mydb)