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
    omniauth.provider :bnet, SiteSetting.battle_net_client_id, SiteSetting.battle_net_client_secret, scope: "wow.profile"
  end
end

auth_provider :title => 'Battle.net',
    :message => 'Log in via Battle.net',
    :frame_width => 920,
    :frame_height => 800,
    :authenticator => BattleNetAuthenticator.new
    
register_css <<CSS

.btn-social.bnet {
  background: #46698f;  
}

.btn-social.bnetbefore {
  content: "L";
}

CSS