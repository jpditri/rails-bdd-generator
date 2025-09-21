# Create admin user
User.create!(
  email: 'admin@example.com',
  password: 'password123',
  first_name: 'Admin',
  last_name: 'User',
  role: 'admin'
)

puts "Created admin user: admin@example.com / password123"

# Create sample data
# Create sample books
# Create sample orders
# Create sample order_items
# Create sample reviews
