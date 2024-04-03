using StatsBase

@time begin

    function build_denominators_for_normalization(number_of_criteria, decision_matrix)
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

    function build_weighted_normalized_matrix(number_of_criteria, decision_matrix, weight)
        denominators = build_denominators_for_normalization(number_of_criteria, decision_matrix)

        weighted_normalized_matrix = []

        for alternative_scores in decision_matrix
            weighted_normalized_alternative_scores = []

            for column_number in 1:number_of_criteria
                weighted_normalized_score = weight[column_number] * alternative_scores[column_number] / denominators[column_number]
                push!(weighted_normalized_alternative_scores, weighted_normalized_score)
            end
            
            push!(weighted_normalized_matrix, weighted_normalized_alternative_scores)
        end

        return weighted_normalized_matrix
    end

    function build_matrix_for_ideal_solution(number_of_criteria, weighted_normalized_matrix)
        matrix_for_ideal_solution = []

        for _ in 1:number_of_criteria
            push!(matrix_for_ideal_solution, [])
        end
        
        for weighted_scores in weighted_normalized_matrix
            for (index, score) in enumerate(weighted_scores)
                push!(matrix_for_ideal_solution[index], score)
            end
        end

        return matrix_for_ideal_solution
    end

    function get_ideal_solution(number_of_criteria, matrix_for_ideal_solution, criteria_type, solution_type)
        ideal_solution_matrix = zeros(Float64, 1, number_of_criteria)

        criterion_type = solution_type == "positive" ? "benefit" : "cost"
        
        for (index, ideal_solution_scores) in enumerate(matrix_for_ideal_solution)
            if criteria_type[index] == criterion_type
                ideal_solution_matrix[index] = maximum(ideal_solution_scores)
            else
                ideal_solution_matrix[index] = minimum(ideal_solution_scores)
            end
        end
        
        return ideal_solution_matrix
    end

    function get_distance_from_positive_ideal(weighted_normalized_matrix, positive_ideal_solutions)
        distance_from_positive = []

        for weighted_scores in weighted_normalized_matrix
            sum_distance = 0

            for (index, weighted_score) in enumerate(weighted_scores)
                sum_distance = sum_distance + (positive_ideal_solutions[index] - weighted_score)^2
            end

            distance = sqrt(sum_distance)
            
            push!(distance_from_positive, distance)
        end

        return distance_from_positive
    end

    function get_distance_from_negative_ideal(weighted_normalized_matrix, negative_ideal_solutions)
        distance_from_negative = []

        for weighted_scores in weighted_normalized_matrix
            sum_distance = 0

            for (index, weighted_score) in enumerate(weighted_scores)
                sum_distance = sum_distance + (weighted_score - negative_ideal_solutions[index])^2
            end

            distance = sqrt(sum_distance)
            
            push!(distance_from_negative, distance)
        end

        return distance_from_negative
    end

    function get_relative_closeness_to_ideal_solution(distance_from_positive, distance_from_negative)
        relative_closeness = []

        for (index, positive_distance) in enumerate(distance_from_positive)
            push!(relative_closeness, distance_from_negative[index] / (positive_distance + distance_from_negative[index]))
        end

        return relative_closeness
    end

    function topsis(weight, decision_matrix, criteria_type)
        number_of_criteria = length(weight)

        weighted_normalized_matrix = build_weighted_normalized_matrix(
            number_of_criteria,
            decision_matrix,
            weight
        )
        
        matrix_for_ideal_solution = build_matrix_for_ideal_solution(
            number_of_criteria,
            weighted_normalized_matrix
        )
        
        positive_ideal_solutions = get_ideal_solution(
            number_of_criteria,
            matrix_for_ideal_solution,
            criteria_type,
            "positive"
        )
        
        negative_ideal_solutions = get_ideal_solution(
            number_of_criteria,
            matrix_for_ideal_solution,
            criteria_type,
            "negative"
        )
        
        distance_from_positive = get_distance_from_positive_ideal(
            weighted_normalized_matrix,
            positive_ideal_solutions
        )
        
        distance_from_negative = get_distance_from_negative_ideal(
            weighted_normalized_matrix,
            negative_ideal_solutions
        )
        
        relative_closeness = get_relative_closeness_to_ideal_solution(
            distance_from_positive,
            distance_from_negative
        )

        rank = ordinalrank(relative_closeness)
        
        return Dict("relative_closeness" => relative_closeness, "rank" => rank)
    end

    criteria_type = ["cost", "benefit", "benefit", "cost", "benefit"]
    weight = [0.2, 0.15, 0.3, 0.25, 0.1]

    decision_matrix = [
        [420, 75, 3, 1, 3],
        [580, 220, 2, 3, 2],
        [350, 80, 4, 2, 1],
        [410, 170, 3, 4, 2]
    ]

    result = topsis(weight, decision_matrix, criteria_type)

end
