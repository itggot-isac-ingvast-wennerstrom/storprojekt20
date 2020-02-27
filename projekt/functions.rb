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

# Takes an array as input and converts it into a string of values or elements for SQL
def arr_to_str(input, mod='')
    str = "("
    input.each do |item|
        if item.is_a?(String)
            str+= mod + item + mod + ','
        else
            str+= item.to_s + ','
        end
    end
    str[-1] = ')'
    return str
end

def generate_text_id(number)
    charset = Array('A'..'Z') + Array('a'..'z') + Array('0'..'9') + ['.', '_', '-', '%']
    return Array.new(number) { charset.sample }.join
end
