import streamlit as st

st.set_page_config(
    page_title="TECHIN 513 Course Website",
    page_icon="📚",
    layout="wide",
)

st.title("TECHIN 513 Course Website")
st.write("Welcome to the TECHIN 513 Course Website")

with st.sidebar:
    st.header("Annoucements")
    st.header("Course Information")

# Announcements section
st.header("Announcements")
with st.container():
    col1, col2 = st.columns(2)
    with col1:
        st.write("Class is at GIX127")
    with col2:
        st.markdown("Assignment 1 is due :red[next week]")

# Course Information section
st.header("Course Information")
with st.container():
    tab1, tab2, tab3 = st.tabs(["Course Description", "Course Schedule", "Grading Policy"])

    with tab1:
        col1, col2 = st.columns(2)
        with col1:
            st.info("This course is about ...")
        with col2:
            st.warning("Warning: This course is not for you")
    with tab2:
        col1, col2, col3 = st.columns(3)
        with col1:
            with st.expander("Course Schedule"):
                st.markdown("""- Week 1: Introduction
                            - Week 2: Python Basics
                            - Week 3: Data Structures
                            - Week 4: Algorithms
                            - Week 5: Machine Learning
                            - Week 6: Deep Learning
                            - Week 7: Natural Language Processing
                            - Week 8: Computer Vision
                            - Week 9: Robotics
                            - Week 10: Final Project""")
        with col2:
            
