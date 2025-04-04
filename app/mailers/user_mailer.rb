class UserMailer < ApplicationMailer
  def welcome_email(user)
    @user = user
    
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    
    message_params = {
      from: 'no-reply@flowgrind.com',
      to: 'kevin.tenisson@gmail.com',
      subject: 'Welcome to FlowGrind',
      text: "Hey kevin.tenisson@gmail.com, welcome to FlowGrind! We're excited to have you.",
      html: render_to_string(template: 'user_mailer/welcome_email', layout: false)
    }

    mg_client.send_message(ENV['MAILGUN_DOMAIN'], message_params)
  end
end
