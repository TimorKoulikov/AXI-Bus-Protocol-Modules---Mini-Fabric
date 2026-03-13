/*------------------------------------------------------------------------------
 * File          : testBlock.v
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Mar 12, 2026
 * Description   :
 *------------------------------------------------------------------------------*/

module testBlock #() (
aclk
);
import /src/main/resources
		
		

		always_ff @(posedge aclk) begin
			if(valid)
				data_out <= data_in;
				valid_out <=1'b1;
			end
			else begin
				valid_out >=1'b0;
			end
		end
endmodule