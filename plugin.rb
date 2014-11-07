# name: discourse-battle.net
# about: adds Battle.net OAuth support to discourse
# version: 0.0.1
# authors: Alex Castle

require File.dirname(__FILE__) + "/../../app/models/oauth2_user_info"
gem 'omniauth-bnet', '1.0.1'

class BattleNetAuthenticator < ::Auth::Authenticator
  def name
    'bnet'
  end

  def after_authenticate(auth_token)
    result = Auth::Result.new

    oauth2_uid = auth_token[:uid]
    data = auth_token[:info]
    result.email = email = data[:email]
    result.name = name = data[:name]

    oauth2_user_info = Oauth2UserInfo.where(uid: oauth2_uid, provider: 'bnet').first
    result.user = oauth2_user_info.try(:user)

    if !result.user && !email.blank? && result.user = User.find_by_email(email)
      Oauth2UserInfo.create({ uid: oauth2_uid,
                              provider: 'bnet',
                              name: name,
                              email: email,
                              user_id: result.user.id })
    end

    result.email_valid = true
    result
  end

  def register_middleware(omniauth)
    omniauth.provider :bnet, :setup => lambda { |env|
      strategy = env["omniauth.strategy"]
      strategy.options[:client_id] = SiteSetting.battle_net_client_id
      strategy.options[:client_secret] = SiteSetting.battle_net_client_secret
      strategy.options[:scope] = "wow.profile"
    }
  end
end

auth_provider :title => 'Battle.net',
  :message => 'Log in via Battle.net',
  :frame_width => 450,
  :frame_height => 470,
  :authenticator => BattleNetAuthenticator.new
    
register_css <<CSS
.btn-social.bnet {
	background: #000000;
	padding: 20px 10px 10px 10px;
	border-radius: 4px;
	font-size: 0px;
	width: 270px;
	height: 70px;
	background-repeat: no-repeat;
	background-position: 5px 10px;
	background-image: url(data:image/png;base64,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) 
}
CSS