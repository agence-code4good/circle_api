# mihivai user
User.create!(admin: true, email: "dev@mihivai.com", password: 'macpass', password_confirmation: 'macpass')

# client user -> mail et mdp à changer selon le client
User.create!(admin: true, email: "client@gmail.com", password: 'MihivaiClient2024!', password_confirmation: 'MihivaiClient2024!')
