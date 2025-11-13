Warden::Strategies.add(:password_authenticatable) do
  def valid?
    params['user'] && params['user']['identity'] && params['user']['password']
  end

  def authenticate!
    resource = User.find_for_database_authentication(identity: params['user']['identity'])
    if resource && resource.valid_password?(params['user']['password'])
      success!(resource)
    else
      fail!(:invalid)
    end
  end
end
