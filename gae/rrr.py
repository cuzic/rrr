import os
import cgi
import yaml

from google.appengine.api import users
from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app
from google.appengine.ext import db
from google.appengine.api import mail

class MainPage(webapp.RequestHandler):
  def get(self):
    self.response.out.write("""
      <html>
        <body>
        </body>
      </html>""")

class Command(db.Model):
  body = db.StringProperty(multiline=True)
  title = db.StringProperty()
  sended = db.BooleanProperty()

class RegistPage(webapp.RequestHandler):
  def post(self):
    self.regist()

  def get(self):
    self.regist()

  def regist(self):
    command = Command()
    command.body = self.request.get('command')
    command.title = self.request.get('title')
    command.sended = False
    command.put()
    self.redirect('/')

class SendMail(webapp.RequestHandler):
  config = yaml.safe_load(open(os.path.join(
    os.path.dirname(__file__), 'config.yaml')))

  def get(self):
    html = ""

    commands = db.GqlQuery("SELECT * FROM Command WHERE sended = FALSE LIMIT 1")
    for command in commands:
      html += command.body
      mail.send_mail(sender=self.config['sender'],
                   to=self.config['to'],
                   subject=command.title,
                   body=command.body)
      command.sended = True
      command.save()
    self.response.out.write(
          "<html><body>"+html+"</body></html>")

application = webapp.WSGIApplication(
                                   [('/', MainPage),
                                    ('/regist', RegistPage),
                                    ('/sendmail', SendMail)],
                                     debug=True)

def main():
  run_wsgi_app(application)

if __name__ == "__main__":
  main()
