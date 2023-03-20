import paramiko, os, os.path
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders

#Removing files which are on append list in the code..
if os.path.isfile('ibm_v7k_log.csv'):
    os.remove("ibm_v7k_log.csv")

#Setting environment variables..
os.system('./ibm_env.sh')
IBM_USR = os.getenv("IBM_USR")
IBM_PWD = os.getenv("IBM_PWD")

#Using Paramiko to SSH into the storage arrays..
p = paramiko.SSHClient()
p.set_missing_host_key_policy(paramiko.AutoAddPolicy())
with open('ibm_arrays', 'rb') as ibm_arrays:
    for IBM_ARRAY in ibm_arrays:
        header=str('---------------------------' + IBM_ARRAY + '---------------------------')
        tailer=str('-----------------------------------------------------------------------')
        with open('ibm_v7k_log.csv', 'a') as output:
            output.write(header + '\n')
        p.connect(IBM_ARRAY,port=22, username=IBM_USR, password=IBM_PWD)
        with open('v7k_commands', 'rb') as v7k_commands:
            for V7K_COMMAND in v7k_commands:
                stdin, stdout, stderr = p.exec_command(V7K_COMMAND)
                opt = stdout.readlines()
                opt ="".join(opt)
                with open('ibm_v7k_log.csv', 'a') as output:
                    output.write(opt + '\n')
        with open('ibm_v7k_log.csv', 'a') as output:
            output.write(tailer + '\n')

#Setting mail addresses..
sender = 'storageadmin@abc.com'
tomail = 'recipient@abc.com'
ccmail = ""

#Mail sending module..
mail_content = """Dear Recipient,

IBM V7000 Daily Health check report.

Please find the attached Health check report for all the IBM V7000 storage arrays.

Regards,
Storage-Admin."""
attach_file_name = 'ibm_v7k_log.csv'
attach_file = open(attach_file_name, 'rb')
payload = MIMEBase('application', 'octate-stream')
payload.set_payload(attach_file.read())
encoders.encode_base64(payload)
payload.add_header('Content-Decomposition', 'attachment', filename=attach_file_name)
msg = MIMEMultipart()
msg.attach(MIMEText(mail_content, 'plain'))
msg.attach(payload)
msg['Subject'] = "IBM V7000 daily Health check"
msg['From'] = sender
msg['To'] = tomail
msg['cc'] = ccmail
cclist = []
cclist.append(tomail)
try:
    smtpObj = smtplib.SMTP('172.x.x.x')
    smtpObj.ehlo()
    smtpObj.starttls()
    smtpObj.sendmail(sender, cclist, msg.as_string())
    print("Successfully sent email")
except SMTPException:
    print("Error: unable to send email")
