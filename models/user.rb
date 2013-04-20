# encoding: utf-8
require "oauth2"
require "oj"

class User
  attr_accessor :api_state

  def initialize(options = {})
    self.api_state = options[:state] || SecureRandom.hex(15)
    @auth_token = options[:token] unless options[:token].nil?
  end

  def authorize_url
    api_client.auth_code.authorize_url(
      :scope => "r_fullprofile r_contactinfo r_emailaddress",
      :redirect_uri => "http://127.0.0.1:9393/verify",
      :state => api_state)
  end

  def authorized?
    !auth_token.nil?
  end

  def validate(code)
    token = api_client.auth_code.get_token(code, :redirect_uri => "http://127.0.0.1:9393/verify")
    @auth_token = token.token
    populate_data
    @auth_token
  end

  def data
    @data ||= populate_data
  end

  private

  def populate_data
    response = access_token.get("https://www.linkedin.com/v1/people/~:(first-name,last-name,email-address,specialties,positions,honors,interests,languages,skills,certifications,educations,courses,volunteer,phone-numbers,main-address)?format=json")
    @data = Oj.load(response.body)
  end

  def auth_token
    @auth_token
  end

  def access_token
    @access_token ||= OAuth2::AccessToken.new(api_client, auth_token, {
      :mode => :query,
      :param_name => "oauth2_access_token"})
  end

  def api_client
    @@api_client ||= OAuth2::Client.new(
      ENV['LINKEDIN_APP_KEY'],
      ENV['LINKEDIN_APP_SECRET'],
      :authorize_url => "/uas/oauth2/authorization?response_type=code",
      :token_url => "/uas/oauth2/accessToken",
      :site => "https://www.linkedin.com")
  end
end