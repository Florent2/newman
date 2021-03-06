require_relative "example_helper"

# This is a cheap and possibly buggy clone of librelist.org's automatic
# mailing list creation
#
# Settings:
#
# - `application.librelist_db`<br>
#     path to mailing list pstore file, relative to application root
#
module Newman
  module Examples
    LibreList = Newman::Application.new do
      helpers do
        def load_list(name)
          store = Newman::Store.new(settings.application.librelist_db)
          Newman::MailingList.new(name, store)
        end
      end

      match :list_id, "[^.]+"

      to(:tag, "{list_id}.subscribe") do
        list = load_list(params[:list_id])

        if list.subscriber?(sender)
          respond :subject  => "ERROR: Already subscribed",
                  :body     => template("subscribe-error"),
                  :reply_to => "test+#{params[:list_id]}@#{domain}"
        else
          list.subscribe(sender)

          respond :subject => "SUBSCRIBED!",
                  :body    => template("subscribe-success"),
                  :reply_to => "test+#{params[:list_id]}@#{domain}"
        end
      end

      to(:tag, "{list_id}.unsubscribe") do
        list = load_list(params[:list_id])

        if list.subscriber?(sender)
          list.unsubscribe(sender)

          respond :subject => "UNSUBSCRIBED!",
                  :body    => template("unsubscribe-success")
        else
          respond :subject => "ERROR: Not on subscriber list",
                  :body    => template("unsubscribe-error"),
                  :reply_to => "test+#{params[:list_id]}@#{domain}"
        end
      end

      to(:tag, "{list_id}") do
        list = load_list(params[:list_id])

        if list.subscriber?(sender)
          forward_message :bcc      => list.subscribers.join(", "),
                          :reply_to => "test+#{params[:list_id]}@#{domain}"
        else
          respond :subject => "You are not subscribed",
                  :body    => template("non-subscriber-error"),
                  :reply_to => "test+#{params[:list_id]}@#{domain}"
        end
      end

      default do
        respond :subject => "FAIL"
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  Newman::Server.simple(Newman::Examples::LibreList, "config/environment.rb")
end
