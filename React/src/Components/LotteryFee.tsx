import React from "react";

const FeeForm = () => {

    const handleSubmit = (event: React.FormEvent) => {
        event?.preventDefault();
    }
    return (
        <form onSubmit={handleSubmit}> 
          <label>Enter fee to play</label>
          <input placeholder='0.001'>
          </input>
          <button 
          type="submit">
            Submit
          </button>
        </form>
      );
    };
    

export  default FeeForm;