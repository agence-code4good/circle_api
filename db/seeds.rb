# code4good user
User.create!(admin: true, email: "dev@code4good.fr", password: 'macpass', password_confirmation: 'macpass')

# partners
Partner.create!(name: "Code4Good", code: "code4good")
Partner.create!(name: "Circle", code: "circle")

# identifier pairs
IdentifierPair.create!(partner: Partner.find_by(code: "code4good"), my_alias: "c_1234567890", partner_alias: "p_1234567890")
