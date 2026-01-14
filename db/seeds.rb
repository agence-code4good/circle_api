# code4good user
User.create!(admin: true, email: "dev@code4good.fr", password: 'macpass', password_confirmation: 'macpass')

# partners
Partner.create!(name: "Code4Good", code: "code4good")
Partner.create!(name: "Circle", code: "circle")
Partner.create!(name: "Château Gazin", code: "chateau_gazin")
Partner.create!(name: "La Cave à Part", code: "la_cave_a_part")
