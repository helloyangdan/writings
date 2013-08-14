class SplitUserAndSpace < Mongoid::Migration
  def self.up
    # remove Workspace
    Space.all.rename :creator_id => :user_id
    Invitation.all.rename :workspace_id => :space_id

    # split user
    Space.where(:_type => 'Workspace').rename(:creator_id => :user_id)
    Space.all.unset(:_type)
    user_attributes = [:email, :name, :full_name, :description, :password_digest, :password_reset_token, :password_reset_token_created_at, :locale, :created_at, :updated_at]
    Space.where(:user_id => nil).asc(:_id).each do |space|
      user_attr = space.attributes.symbolize_keys.slice(*(user_attributes + [:_id]))
      user = User.new(user_attr)
      user.save(:validate => false)
      space.update_attribute :user_id, user.id
      space.members << user
    end
    Space.all.unset(user_attributes - [:name, :full_name, :description])

    # Order
    Order.all.rename :user_id => :space_id
  end

  def self.down
  end
end
