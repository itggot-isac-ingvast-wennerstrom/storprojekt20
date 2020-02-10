#Validates email
def validate_email(email)
    first_check = false
    #Checks each character
    email.each_char do |letter|
        #Checks for @
        if letter == "@"
            first_check = true
        end
        #Checks for a dot 
        if first_check
            if letter == "."
                return true
            end
        end 
    end
    return false
end