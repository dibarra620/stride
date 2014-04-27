require 'sinatra'
require "sinatra/cookies"
require 'omniauth-facebook'
require './helpers/get_post'

enable :sessions

set :protection, :except => :frame_options

configure do
  set :redirect_uri, nil
end

OmniAuth.config.on_failure = lambda do |env|
  [302, {'Location' => '/auth/failure', 'Content-Type' => 'text/html'}, []]
end

APP_ID = "261024930748187"
APP_SECRET = "b56fe56d4a31f6a01544abf6b35d7edf"

use OmniAuth::Builder do
  provider :facebook, APP_ID, APP_SECRET, { :scope => 'email, status_update, publish_stream' }
end

get_post '/' do
  @articles = []
  @articles << {:title => 'Getting Started with Heroku', :url => 'https://devcenter.heroku.com/articles/quickstart'}
  @articles << {:title => 'Deploying Rack-based apps in Heroku', :url => 'http://docs.heroku.com/rack'}
  @articles << {:title => 'Learn Ruby in twenty minutes', :url => 'http://www.ruby-lang.org/en/documentation/quickstart/'}

  erb :index
end

get '/auth/facebook/callback' do
  fb_auth = request.env['omniauth.auth']
  session['fb_auth'] = fb_auth
  session['fb_token'] = cookies[:fb_token] = fb_auth['credentials']['token']
  session['fb_error'] = nil
  redirect '/'
end

get '/auth/failure' do
  clear_session
  session['fb_error'] = 'In order to use all the Facebook features in this site you must allow us access to your Facebook data...<br />'
  redirect '/'
end

get '/login' do
  if settings.redirect_uri
    # we're in FB
    erb :dialog_oauth
  else
    # we aren't in FB (standalone app)
    redirect '/auth/facebook'
  end
end

get '/logout' do
  clear_session
  redirect '/'
end

post '/canvas/' do

  redirect '/auth/failure' if request.params['error'] == 'access_denied'

  settings.redirect_uri = 'https://apps.facebook.com/stridefitness/'

  url = request.params['code'] ? "/auth/facebook?signed_request=#{request.params['signed_request']}&state=canvas" : '/login'
  redirect url
end

def clear_session
  session['fb_auth'] = nil
  session['fb_token'] = nil
  session['fb_error'] = nil
  cookies[:fb_token] = nil
end

__END__

@@ dialog_oauth
<script>
  var oauth_url = 'https://www.facebook.com/dialog/oauth/';
  oauth_url += '?client_id=153304591365687';
  oauth_url += '&redirect_uri=' + encodeURIComponent('<%=settings.redirect_uri%>');
  oauth_url += '&scope=email, status_update, publish_stream'

  window.top.location = oauth_url;
</script>