def validate_email(email)
    first_check = false
    email.each_char do |letter|
        if letter == "@"
            first_check = true
        end
        if first_check
            if letter == "."
                return true
            end
        end 
    end
    return false
end