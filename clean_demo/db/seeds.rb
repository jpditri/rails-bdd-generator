# Create admin user
User.create!(
  email: 'admin@example.com',
  first_name: 'Admin',
  last_name: 'User',
  role: 'admin'
)

puts "Created admin user: admin@example.com"

# Create sample data

