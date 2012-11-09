#pragma once

/* data.hの前方参照、namespaceの外で宣言しておく */
enum hand;
struct data;

namespace measuring {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

	/// <summary>
	/// Form1 の概要
	/// </summary>
	public ref class Form1 : public System::Windows::Forms::Form
	{
	public:
		Form1(void)
		{
			InitializeComponent();
			//
			//TODO: ここにコンストラクター コードを追加します
			//
			InitializeData();
			InitializeTable();
			ReadyMeasuring();
		}

	protected:
		/// <summary>
		/// 使用中のリソースをすべてクリーンアップします。
		/// </summary>
		~Form1()
		{
			FinalizeData();

			if (components)
			{
				delete components;
			}
		}

	private:
		struct data *data;
		System::String^ inputed;
		System::DateTime^ firstTime;
		System::String^ fileName;

		void InitializeData();
		void FinalizeData();
		void InitializeTable();
		void InitializeTable(System::Windows::Forms::DataGridView^ view, enum hand hand);
		void UpdateTable();
		void UpdateTable(System::Windows::Forms::DataGridView^ view, enum hand hand);
		void ReadyMeasuring();
		void loadFromFile(System::String ^newFileName);
		void saveToFile(System::String ^newFileName);

	private: System::Windows::Forms::Label^  guideLabel;
	private: System::Windows::Forms::SplitContainer^  splitContainer1;
	private: System::Windows::Forms::DataGridView^  leftDataGridView;
	private: System::Windows::Forms::DataGridView^  rightDataGridView;
	private: System::Windows::Forms::TextBox^  inputTextBox;
	private: System::Windows::Forms::OpenFileDialog^  openFileDialog;
	private: System::Windows::Forms::SaveFileDialog^  saveFileDialog;
	private: System::Windows::Forms::MenuStrip^  menuStrip1;
	private: System::Windows::Forms::ToolStripMenuItem^  fileToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  openToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  saveToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  saveAsToolStripMenuItem;
	private: System::Windows::Forms::ToolStripSeparator^  toolStripMenuItem1;
	private: System::Windows::Forms::ToolStripMenuItem^  closeToolStripMenuItem;

	private:
		/// <summary>
		/// 必要なデザイナー変数です。
		/// </summary>
		System::ComponentModel::Container ^components;

#pragma region Windows Form Designer generated code
		/// <summary>
		/// デザイナー サポートに必要なメソッドです。このメソッドの内容を
		/// コード エディターで変更しないでください。
		/// </summary>
		void InitializeComponent(void)
		{
			this->guideLabel = (gcnew System::Windows::Forms::Label());
			this->splitContainer1 = (gcnew System::Windows::Forms::SplitContainer());
			this->leftDataGridView = (gcnew System::Windows::Forms::DataGridView());
			this->rightDataGridView = (gcnew System::Windows::Forms::DataGridView());
			this->inputTextBox = (gcnew System::Windows::Forms::TextBox());
			this->openFileDialog = (gcnew System::Windows::Forms::OpenFileDialog());
			this->saveFileDialog = (gcnew System::Windows::Forms::SaveFileDialog());
			this->menuStrip1 = (gcnew System::Windows::Forms::MenuStrip());
			this->fileToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->openToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->saveToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->saveAsToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->toolStripMenuItem1 = (gcnew System::Windows::Forms::ToolStripSeparator());
			this->closeToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->splitContainer1))->BeginInit();
			this->splitContainer1->Panel1->SuspendLayout();
			this->splitContainer1->Panel2->SuspendLayout();
			this->splitContainer1->SuspendLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->leftDataGridView))->BeginInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->rightDataGridView))->BeginInit();
			this->menuStrip1->SuspendLayout();
			this->SuspendLayout();
			// 
			// guideLabel
			// 
			this->guideLabel->AutoSize = true;
			this->guideLabel->Font = (gcnew System::Drawing::Font(L"Tahoma", 12, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(128)));
			this->guideLabel->Location = System::Drawing::Point(32, 68);
			this->guideLabel->Name = L"guideLabel";
			this->guideLabel->Size = System::Drawing::Size(104, 19);
			this->guideLabel->TabIndex = 0;
			this->guideLabel->Text = L"<fst> <snd>";
			this->guideLabel->UseMnemonic = false;
			// 
			// splitContainer1
			// 
			this->splitContainer1->Dock = System::Windows::Forms::DockStyle::Bottom;
			this->splitContainer1->Location = System::Drawing::Point(0, 133);
			this->splitContainer1->Name = L"splitContainer1";
			this->splitContainer1->Orientation = System::Windows::Forms::Orientation::Horizontal;
			// 
			// splitContainer1.Panel1
			// 
			this->splitContainer1->Panel1->Controls->Add(this->leftDataGridView);
			// 
			// splitContainer1.Panel2
			// 
			this->splitContainer1->Panel2->Controls->Add(this->rightDataGridView);
			this->splitContainer1->Size = System::Drawing::Size(950, 300);
			this->splitContainer1->SplitterDistance = 148;
			this->splitContainer1->TabIndex = 2;
			// 
			// leftDataGridView
			// 
			this->leftDataGridView->AllowUserToAddRows = false;
			this->leftDataGridView->AllowUserToDeleteRows = false;
			this->leftDataGridView->AutoSizeColumnsMode = System::Windows::Forms::DataGridViewAutoSizeColumnsMode::AllCells;
			this->leftDataGridView->ColumnHeadersHeightSizeMode = System::Windows::Forms::DataGridViewColumnHeadersHeightSizeMode::AutoSize;
			this->leftDataGridView->Dock = System::Windows::Forms::DockStyle::Fill;
			this->leftDataGridView->Location = System::Drawing::Point(0, 0);
			this->leftDataGridView->MultiSelect = false;
			this->leftDataGridView->Name = L"leftDataGridView";
			this->leftDataGridView->ReadOnly = true;
			this->leftDataGridView->RowTemplate->Height = 21;
			this->leftDataGridView->ShowEditingIcon = false;
			this->leftDataGridView->Size = System::Drawing::Size(950, 148);
			this->leftDataGridView->StandardTab = true;
			this->leftDataGridView->TabIndex = 0;
			// 
			// rightDataGridView
			// 
			this->rightDataGridView->AllowUserToAddRows = false;
			this->rightDataGridView->AllowUserToDeleteRows = false;
			this->rightDataGridView->AutoSizeColumnsMode = System::Windows::Forms::DataGridViewAutoSizeColumnsMode::AllCells;
			this->rightDataGridView->ColumnHeadersHeightSizeMode = System::Windows::Forms::DataGridViewColumnHeadersHeightSizeMode::AutoSize;
			this->rightDataGridView->Dock = System::Windows::Forms::DockStyle::Fill;
			this->rightDataGridView->Location = System::Drawing::Point(0, 0);
			this->rightDataGridView->MultiSelect = false;
			this->rightDataGridView->Name = L"rightDataGridView";
			this->rightDataGridView->ReadOnly = true;
			this->rightDataGridView->RowTemplate->Height = 21;
			this->rightDataGridView->ShowEditingIcon = false;
			this->rightDataGridView->Size = System::Drawing::Size(950, 148);
			this->rightDataGridView->StandardTab = true;
			this->rightDataGridView->TabIndex = 0;
			// 
			// inputTextBox
			// 
			this->inputTextBox->AcceptsReturn = true;
			this->inputTextBox->AcceptsTab = true;
			this->inputTextBox->BackColor = System::Drawing::Color::Azure;
			this->inputTextBox->Font = (gcnew System::Drawing::Font(L"Tahoma", 12, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(128)));
			this->inputTextBox->ImeMode = System::Windows::Forms::ImeMode::Disable;
			this->inputTextBox->Location = System::Drawing::Point(240, 65);
			this->inputTextBox->Multiline = true;
			this->inputTextBox->Name = L"inputTextBox";
			this->inputTextBox->ReadOnly = true;
			this->inputTextBox->Size = System::Drawing::Size(155, 27);
			this->inputTextBox->TabIndex = 1;
			this->inputTextBox->KeyDown += gcnew System::Windows::Forms::KeyEventHandler(this, &Form1::inputTextBox_KeyDown);
			// 
			// openFileDialog
			// 
			this->openFileDialog->AddExtension = false;
			// 
			// saveFileDialog
			// 
			this->saveFileDialog->AddExtension = false;
			// 
			// menuStrip1
			// 
			this->menuStrip1->Items->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(1) {this->fileToolStripMenuItem});
			this->menuStrip1->Location = System::Drawing::Point(0, 0);
			this->menuStrip1->Name = L"menuStrip1";
			this->menuStrip1->Size = System::Drawing::Size(950, 24);
			this->menuStrip1->TabIndex = 3;
			// 
			// fileToolStripMenuItem
			// 
			this->fileToolStripMenuItem->DropDownItems->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(5) {this->openToolStripMenuItem, 
				this->saveToolStripMenuItem, this->saveAsToolStripMenuItem, this->toolStripMenuItem1, this->closeToolStripMenuItem});
			this->fileToolStripMenuItem->Name = L"fileToolStripMenuItem";
			this->fileToolStripMenuItem->Size = System::Drawing::Size(36, 20);
			this->fileToolStripMenuItem->Text = L"&File";
			// 
			// openToolStripMenuItem
			// 
			this->openToolStripMenuItem->Name = L"openToolStripMenuItem";
			this->openToolStripMenuItem->Size = System::Drawing::Size(138, 22);
			this->openToolStripMenuItem->Text = L"&Open...";
			this->openToolStripMenuItem->Click += gcnew System::EventHandler(this, &Form1::openToolStripMenuItem_Click);
			// 
			// saveToolStripMenuItem
			// 
			this->saveToolStripMenuItem->Name = L"saveToolStripMenuItem";
			this->saveToolStripMenuItem->Size = System::Drawing::Size(138, 22);
			this->saveToolStripMenuItem->Text = L"&Save";
			this->saveToolStripMenuItem->Click += gcnew System::EventHandler(this, &Form1::saveToolStripMenuItem_Click);
			// 
			// saveAsToolStripMenuItem
			// 
			this->saveAsToolStripMenuItem->Name = L"saveAsToolStripMenuItem";
			this->saveAsToolStripMenuItem->Size = System::Drawing::Size(138, 22);
			this->saveAsToolStripMenuItem->Text = L"Save &As...";
			this->saveAsToolStripMenuItem->Click += gcnew System::EventHandler(this, &Form1::saveAsToolStripMenuItem_Click);
			// 
			// toolStripMenuItem1
			// 
			this->toolStripMenuItem1->Name = L"toolStripMenuItem1";
			this->toolStripMenuItem1->Size = System::Drawing::Size(135, 6);
			// 
			// closeToolStripMenuItem
			// 
			this->closeToolStripMenuItem->Name = L"closeToolStripMenuItem";
			this->closeToolStripMenuItem->ShortcutKeys = static_cast<System::Windows::Forms::Keys>((System::Windows::Forms::Keys::Alt | System::Windows::Forms::Keys::F4));
			this->closeToolStripMenuItem->Size = System::Drawing::Size(138, 22);
			this->closeToolStripMenuItem->Text = L"&Close";
			this->closeToolStripMenuItem->Click += gcnew System::EventHandler(this, &Form1::closeToolStripMenuItem_Click);
			// 
			// Form1
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 12);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(950, 433);
			this->Controls->Add(this->inputTextBox);
			this->Controls->Add(this->splitContainer1);
			this->Controls->Add(this->guideLabel);
			this->Controls->Add(this->menuStrip1);
			this->MainMenuStrip = this->menuStrip1;
			this->Name = L"Form1";
			this->Text = L"measuring";
			this->splitContainer1->Panel1->ResumeLayout(false);
			this->splitContainer1->Panel2->ResumeLayout(false);
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->splitContainer1))->EndInit();
			this->splitContainer1->ResumeLayout(false);
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->leftDataGridView))->EndInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->rightDataGridView))->EndInit();
			this->menuStrip1->ResumeLayout(false);
			this->menuStrip1->PerformLayout();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion

	private: System::Void inputTextBox_KeyDown(System::Object^  sender, System::Windows::Forms::KeyEventArgs^  e);
	private: System::Void closeToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e);
	private: System::Void openToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e);
	private: System::Void saveToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e);
	private: System::Void saveAsToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e);
};
}
