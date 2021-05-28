function coefficient = PearsonCo(ArrayA,ArrayB)

	meanA = mean(ArrayA);
	meanB = mean(ArrayB);

	summation = 0;
	sumASqu = 0;
	sumBSqu = 0;
	for i = 1 : 1 : 8
		result = (ArrayA(i) - meanA)*(ArrayB(i)- meanB);
		summation = summation + result;
	end

	for i = 1 : 1 : 8
		result = (ArrayA(i) - meanA)*(ArrayA(i)- meanA);
		sumASqu = summation + result;
	end


	for i = 1 : 1 : 8
		result = (ArrayB(i) - meanB)*(ArrayB(i)- meanB);
		sumBSqu = summation + result;
	end

	down = sqrt(double(sumASqu*sumBSqu));

	coefficient = summation / down;
