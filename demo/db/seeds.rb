# Create admin user
User.create!(
  email: 'admin@example.com',
  first_name: 'Admin',
  last_name: 'User',
  role: 'admin'
)

puts "Created admin user: admin@example.com"

# Create sample data
puts "Creating sample books..."
books = [
  {
    title: "The Great Gatsby",
    author: "F. Scott Fitzgerald",
    isbn: "978-0-7432-7356-5",
    description: "A classic American novel set in the Jazz Age.",
    price: 12.99,
    stock_quantity: 25,
    published_at: Date.new(1925, 4, 10),
    category: "Fiction",
    active: true
  },
  {
    title: "To Kill a Mockingbird",
    author: "Harper Lee",
    isbn: "978-0-06-112008-4",
    description: "A powerful story of racial injustice and childhood innocence.",
    price: 14.99,
    stock_quantity: 30,
    published_at: Date.new(1960, 7, 11),
    category: "Fiction",
    active: true
  },
  {
    title: "1984",
    author: "George Orwell",
    isbn: "978-0-452-28423-4",
    description: "A dystopian social science fiction novel.",
    price: 13.99,
    stock_quantity: 20,
    published_at: Date.new(1949, 6, 8),
    category: "Science Fiction",
    active: true
  }
]

books.each do |book_attrs|
  Book.create!(book_attrs)
end

puts "Created #{books.length} sample books"
puts "Database seeded successfully!"
