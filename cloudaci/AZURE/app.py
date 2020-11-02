from flask import Flask, render_template
from flaskext.mysql import MySQL
import random
import base64

app = Flask(__name__)
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 3600
app.config['MYSQL_DATABASE_USER']='cisco'
app.config['MYSQL_DATABASE_PASSWORD']='cisco'
app.config['MYSQL_DATABASE_DB']='ciscodb'
app.config['MYSQL_DATABASE_HOST']='db.acidemo.azure.com' 

mysql = MySQL()
mysql.init_app(app)

@app.route("/")
def main():
    return render_template('index.html')

@app.route('/showDog')
def showSignUp():
    conn = mysql.connect()
    cursor = conn.cursor()
    cursor.execute("SELECT img from pics where idpic='" + str(random.randint(1, 12)) +"';")
    data = cursor.fetchone()[0]
    if data is None:
     return "could not fetch dog!"
    else:
     dog64 = base64.b64encode(data)
    return render_template('showdog.html', dog=dog64)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)

