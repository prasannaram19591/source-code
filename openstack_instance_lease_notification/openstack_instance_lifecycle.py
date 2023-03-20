import sys
import re
import os
import os.path
import smtplib
from itertools import chain
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from datetime import date
import datetime as dt

#Collecting openstack server list
os.system('./source.sh')

#Removing files which are on append list in the code..
if os.path.isfile('metadata.csv'):
    os.remove("metadata.csv")
if os.path.isfile('delete_list.csv'):
    os.remove("delete_list.csv")
if os.path.isfile('mailbody.csv'):
    os.remove("mailbody.csv")
if os.path.isfile('mailbody.csv'):
    os.remove("mailbody.csv")
if os.path.isfile('instance_notification_log.csv'):
    os.remove("instance_notification_log.csv")
if os.path.isfile('logmailbody.csv'):
    os.remove("logmailbody.csv")

#Collecting metadata for servers..
with open('serverlist.csv', 'rb') as f:
    for line in f:
        if 'Retirement' in line:
            ret_dt_val = line.index("Retirement Date")
            owner_val =  str(line.split('Owner=')[1])
            ins_name_val = str(line.split('|')[2])           
            ins_ip_val = line.index("=")
            ins_ip_tmp = str(line[ins_ip_val:(ins_ip_val + 30)])
            ins_ip = str(ins_ip_tmp.split('=')[1])
            owner = str(owner_val.split("'")[1])
            ins_name = str(ins_name_val.split(" ")[1])
            k = str(line[ret_dt_val:(ret_dt_val + 30)])
            if not 'Nil' in k:
                if not 'N/A' in k:
                    if not 'Never' in k:
                        if not 'Owner' in k:
                            try:
                                ret_dt_tmp = str(k.split("='")[1])
                                ret_dt = str(ret_dt_tmp.split("'")[0])
                                print ins_name,ret_dt,owner
                                lines = str(ins_name + ' ' + ret_dt + ' ' + owner + ' ' + ins_ip)
                                with open('metadata.csv', 'a') as output:
                                    output.write(lines + '\n')
                            except:
                                print("An exception occurred")

#Setting mail addresses..
sender = 'sender@abc.com'
ccmail = "ccmail@abc.com"
openstack_admin = "admin@abc.com"

mail_own_tmp1 = str(openstack_admin.split('@')[0])
mail_own_tmp2 = str(mail_own_tmp1.split('.')[0])
mail_own_tmp3 = str(mail_own_tmp2.split('_')[0])
opsk_adm = str(mail_own_tmp3.capitalize())

#Setting todays date for comparison..
today = date.today()
now = str(today)

#Setting 3 level notification days..
remainder1_days = 45
remainder2_days = 30
remainder3_days = 15
rem1 = str(remainder1_days)
rem2 = str(remainder2_days)
rem3 = str(remainder3_days)

#Formatting the retirement date, instance name, instance ip and owner..
with open('metadata.csv', 'rb') as f:
    for line in f:
        instance_name = str(line.split(' ')[0])
        retirement_date = str(line.split(' ')[1])
        instance_owner = str(line.split(' ')[2])
        mail_own_tmp1 = str(instance_owner.split('@')[0])
        mail_own_tmp2 = str(mail_own_tmp1.split('.')[0])
        mail_own_tmp3 = str(mail_own_tmp2.split('_')[0])
        mail_own = str(mail_own_tmp3.capitalize())
        instance_ip = str(line.split(' ')[3])
        year = str(retirement_date.split("-")[2])
        month = str(retirement_date.split("-")[1])
        date = str(retirement_date.split("-")[0])

        #Converting month format to integer..
        if month == "Jan":
            month_num = 1
        if month == "Feb":
            month_num = 2
        if month == "Mar":
             month_num = 3
        if month == "Apr":
             month_num = 4
        if month == "May":
             month_num = 5
        if month == "Jun":
             month_num = 6
        if month == "Jul":
             month_num = 7
        if month == "Aug":
             month_num = 8
        if month == "Sep":
             month_num = 9
        if month == "Oct":
             month_num = 10
        if month == "Nov":
             month_num = 11
        if month == "Dec":
             month_num = 12
        
        #Code to compare the date difference and convert to days..
        ins_yr = int(year)
        ins_date = int(date)
        ins_ret_dt = dt.date(ins_yr, month_num, ins_date)
        print ins_ret_dt
        diff = ins_ret_dt-today
        diff_tmp = str(diff)
        days_str = diff_tmp.split("days")[0]
        days = int(days_str)
        
        #Compute expired instances and save to file..
        days_num = float(days)
        if days_num < 0:
            lines = str(instance_name)
            with open('delete_list.csv', 'a') as output:
                output.write(lines + '\n')
                output.close()

        print days

        #Main code block to process instances that met first remainder days..
        if days == remainder1_days:

            #saving the mailed instances list to a log file..
            with open('instance_notification_log.csv', 'a') as output:
                log = (" User " + instance_owner + " is notified on " + now + " whose instance " + instance_name + " is about to expire in " + rem1 + " days.")
                output.write(log + '\n')
                output.close()

            #Mail sending code block for first notification..
            msg = """Hi {},

            Instance lease notification - 1

            Your vm {} with ip {} will expire in {} days. Please respond to this email with new lease extension.
            
Regards,
EV_DEVIT.""".format(mail_own, instance_name, instance_ip, days)
            #Print the message..
            BODY_TEXT = msg
            msg = MIMEMultipart('alternative')
            msg['Subject'] = "Openstack Instance lease expiry Notification"
            msg['From'] = sender
            msg['To'] = instance_owner
            msg['cc'] = ccmail
            part1 = MIMEText(BODY_TEXT, 'plain')
            msg.attach(part1)
            try:
                smtpObj = smtplib.SMTP('10.x.x.x')
                smtpObj.sendmail(sender, ccmail, msg.as_string())
                print("Successfully sent email")
            except SMTPException:
                print("Error: unable to send email")

        #Main code block to process instances that met second remainder days..
        if days == remainder2_days:

            #saving the mailed instances list to a log file..
            with open('instance_notification_log.csv', 'a') as output:
                log = (" User " + instance_owner + " is notified on " + now + " whose instance " + instance_name + " is about to expire in " + rem2 + " days.")
                output.write(log + '\n')
                output.close()
            
            #Mail sending code block for second notification..
            msg = """Hi {},

            Instance lease notification - 2

            Your vm {} with ip {} will expire in {} days. Please respond to this email with new lease extension to avoid vm unavailability.
            
Regards,
EV_DEVIT.""".format(mail_own, instance_name, instance_ip, days)
            #Print the message..
            BODY_TEXT = msg
            msg = MIMEMultipart('alternative')
            msg['Subject'] = "Openstack Instance lease expiry Notification"
            msg['From'] = sender
            msg['To'] = instance_owner
            msg['cc'] = ccmail
            part1 = MIMEText(BODY_TEXT, 'plain')
            msg.attach(part1)
            try:
                smtpObj = smtplib.SMTP('10.x.x.x')
                smtpObj.sendmail(sender, ccmail, msg.as_string())
                print("Successfully sent email")
            except SMTPException:
                print("Error: unable to send email")

        #Main code block to process instances that met final remainder days..
        if days == remainder3_days:

            #saving the mailed instances list to a log file..
            with open('instance_notification_log.csv', 'a') as output:
                log = (" User " + instance_owner + " is notified on " + now + " whose instance " + instance_name + " is about to expire in " + rem3 + " days.")
                output.write(log + '\n')
                output.close()

            #Mail sending code block for final notification..
            msg = """Hi {},

            Instance lease notification - 3

            Your vm {} with ip {} will expire in {} days. Please respond to this email with new lease extension. Please note that this is the final notification and the vm will be unavailable if no response is received.
            
Regards,
EV_DEVIT.""".format(mail_own, instance_name, instance_ip, days)
            #Print the message..
            BODY_TEXT = msg
            msg = MIMEMultipart('alternative')
            msg['Subject'] = "Openstack Instance lease expiry Notification"
            msg['From'] = sender
            msg['To'] = instance_owner
            msg['cc'] = ccmail
            part1 = MIMEText(BODY_TEXT, 'plain')
            msg.attach(part1)
            try:
                smtpObj = smtplib.SMTP('10.x.x.x')
                smtpObj.sendmail(sender, ccmail, msg.as_string())
                print("Successfully sent email")
            except SMTPException:
                print("Error: unable to send email")

#Purge list notification - collating mail body, instance list, jenkins link and mail footer from different files..
if os.path.isfile('delete_list.csv'):
    now = str(today)
    addressee = "Hi " + str(opsk_adm)
    with open('hi.csv', 'w') as output:
        output.write(addressee + '\n')

    filename = "/root/pythons/hi.csv"
    fp = open(filename, 'rb')
    part1 = fp.read()
    fp.close()
    filename = "/root/pythons/line1.csv"
    fp = open(filename, 'rb')
    part2 = fp.read()
    fp.close()
    filename = "/root/pythons/delete_list.csv"
    fp = open(filename, 'rb')
    part3 = fp.read()
    fp.close()
    filename = "/root/pythons/line2.csv"
    fp = open(filename, 'rb')
    part4 = fp.read()
    fp.close()

    #Appending the contents to a single file to send as mail body..
    lines = str(part1)
    with open('mailbody.csv', 'a') as output:
        output.write(lines + '\n')
    lines = str(part2)
    with open('mailbody.csv', 'a') as output:
        output.write(lines + '\n')
    lines = str(part3)
    with open('mailbody.csv', 'a') as output:
        output.write(lines + '\n')
    lines = str(part4)
    with open('mailbody.csv', 'a') as output:
        output.write(lines + '\n')

    SUBJECT = "Openstack Expired instances as on {}.".format(now)
    with open('mailbody.csv', 'rb') as fp:
        msg = MIMEText(fp.read())
        fp.close()
        msg['Subject'] = SUBJECT
        msg['From'] = sender
        msg['To'] = openstack_admin
        msg['cc'] = ccmail
        try:
            s = smtplib.SMTP('10.x.x.x')
            s.sendmail(sender, ccmail, msg.as_string())
            s.quit()
            print("Successfully sent email")
        except SMTPException:
            print("Error: unable to send email")
else:
    print ("There are no instances to purge for today")

#Expiry notification log sending - collating mail body, instance list and mail footer from different files..
if os.path.isfile('instance_notification_log.csv'):
    now = str(today)
    addressee = "Hi " + str(opsk_adm)
    with open('hi.csv', 'w') as output:
        output.write(addressee + '\n')

    filename = "/root/pythons/hi.csv"
    fp = open(filename, 'rb')
    part1 = fp.read()
    fp.close()
    filename = "/root/pythons/logline1.csv"
    fp = open(filename, 'rb')
    part2 = fp.read()
    fp.close()
    filename = "/root/pythons/instance_notification_log.csv"
    fp = open(filename, 'rb')
    part3 = fp.read()
    fp.close()
    filename = "/root/pythons/line2.csv"
    fp = open(filename, 'rb')
    part4 = fp.read()
    fp.close()
    #Appending the contents to a single file to send as mail body..
    lines = str(part1)
    with open('logmailbody.csv', 'a') as output:
        output.write(lines + '\n')
    lines = str(part2)
    with open('logmailbody.csv', 'a') as output:
        output.write(lines + '\n')
    lines = str(part3)
    with open('logmailbody.csv', 'a') as output:
        output.write(lines + '\n')
    lines = str(part4)
    with open('logmailbody.csv', 'a') as output:
        output.write(lines + '\n')

    SUBJECT = "Openstack Expired instances user notification log on {}.".format(now)
    with open('logmailbody.csv', 'rb') as fp:
        msg = MIMEText(fp.read())
        fp.close()
        msg['Subject'] = SUBJECT
        msg['From'] = sender
        msg['To'] = openstack_admin
        msg['cc'] = ccmail
        try:
            s = smtplib.SMTP('10.x.x.x')
            s.sendmail(sender, ccmail, msg.as_string())
            s.quit()
            print("Successfully sent email")
        except SMTPException:
            print("Error: unable to send email")
else:
    print ("There are no users notified today")
