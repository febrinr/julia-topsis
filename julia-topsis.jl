using StatsBase

@time begin

    function build_denominators_for_normalization()
        sum_matrix_columns = zeros(Float64, 1, number_of_criteria)

        for alternative_scores in decision_matrix
            for (index, score) in enumerate(alternative_scores)
                sum_matrix_columns[index] = sum_matrix_columns[index] + score^2
            end
        end

        denominators = []

        for sum_score in sum_matrix_columns
            push!(denominators, sqrt(sum_score))
        end

        return denominators
    end

    function build_weighted_normalized_matrix()
        denominators = build_denominators_for_normalization()

        weighted_normalized = []

        for alternative_scores in decision_matrix
            weighted_normalized_alternative_scores = []

            for column_number in 1:number_of_criteria
                weighted_normalized_score = weight[column_number] * alternative_scores[column_number] / denominators[column_number]
                
                push!(weighted_normalized_alternative_scores, weighted_normalized_score)
            end
            
            push!(weighted_normalized, weighted_normalized_alternative_scores)
        end

        return weighted_normalized
    end

    function build_matrix_for_ideal_solution(weighted_normalized)
        matrix_for_ideal_solution = []

        for _ in 1:number_of_criteria
            push!(matrix_for_ideal_solution, [])
        end
        
        for weighted_scores in weighted_normalized
            for (index, score) in enumerate(weighted_scores)
                push!(matrix_for_ideal_solution[index], score)
            end
        end

        return matrix_for_ideal_solution
    end

    function get_ideal_solutions(matrix_for_ideal_solution)
        positive_ideal_solutions = zeros(Float64, 1, number_of_criteria)
        negative_ideal_solutions = zeros(Float64, 1, number_of_criteria)
        
        for (index, ideal_solution_scores) in enumerate(matrix_for_ideal_solution)
            if criteria_type[index] == "benefit"
                positive_ideal_solutions[index] = maximum(ideal_solution_scores)
                negative_ideal_solutions[index] = minimum(ideal_solution_scores)
            else
                positive_ideal_solutions[index] = minimum(ideal_solution_scores)
                negative_ideal_solutions[index] = maximum(ideal_solution_scores)
            end
        end
        
        return Dict("positive" => positive_ideal_solutions, "negative" => negative_ideal_solutions)
    end

    function get_distance_from_ideal_solution(weighted_normalized, ideal_solutions)
        distance_from_positive = []
        distance_from_negative = []

        for weighted_scores in weighted_normalized
            sum_positive_distance = 0
            sum_negative_distance = 0

            for (index, weighted_score) in enumerate(weighted_scores)
                sum_positive_distance += (ideal_solutions["positive"][index] - weighted_score)^2
                sum_negative_distance += (weighted_score - ideal_solutions["negative"][index])^2
            end

            positive_distance = sqrt(sum_positive_distance)
            negative_distance = sqrt(sum_negative_distance)
            
            push!(distance_from_positive, positive_distance)
            push!(distance_from_negative, negative_distance)
        end

        return Dict("positive" => distance_from_positive, "negative" => distance_from_negative)
    end

    function get_distance_from_negative_ideal(weighted_normalized, negative_ideal_solutions)
        distance_from_negative = []

        for weighted_scores in weighted_normalized
            sum_distance = 0

            for (index, weighted_score) in enumerate(weighted_scores)
                sum_distance = sum_distance + (weighted_score - negative_ideal_solutions[index])^2
            end

            distance = sqrt(sum_distance)
            
            push!(distance_from_negative, distance)
        end

        return distance_from_negative
    end

    function get_relative_closeness_to_ideal_solution(distance_from)
        relative_closenesses = []

        for (index, positive_distance) in enumerate(distance_from["positive"])
            negative_distance = distance_from["negative"][index]
            relative_closeness = negative_distance / (positive_distance + negative_distance)
            
            push!(relative_closenesses, relative_closeness)
        end

        return relative_closenesses
    end

    function topsis()
        weighted_normalized = build_weighted_normalized_matrix()
        matrix_for_ideal_solution = build_matrix_for_ideal_solution(weighted_normalized)
        ideal_solutions = get_ideal_solutions(matrix_for_ideal_solution)
        distance_from = get_distance_from_ideal_solution(weighted_normalized, ideal_solutions)
        relative_closenesses = get_relative_closeness_to_ideal_solution(distance_from)

        rank = ordinalrank(relative_closenesses)
        
        return Dict("relative_closenesses" => relative_closenesses, "rank" => rank)
    end

    criteria_type = ["cost", "benefit", "benefit", "cost", "benefit"]
    weight = [0.2, 0.15, 0.3, 0.25, 0.1]
    number_of_criteria = length(weight)

    decision_matrix = [
        [420, 75, 3, 1, 3],
        [580, 220, 2, 3, 2],
        [350, 80, 4, 2, 1],
        [410, 170, 3, 4, 2]
    ]

    result = topsis()

end
